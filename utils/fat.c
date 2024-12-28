#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

#define bool u8
#define true 1
#define false 0

//
// http://wiki.osdev.org/FAT#BPB_(BIOS_Parameter_Block)
//
typedef struct {
  u8 JumpCode[3];
  u8 OEMName[8];
  u16 BytesPerSector; // Little Endian
  u8 SectorsPerCluster;
  u16 ReservedSectors;
  u8 FatCount;
  u16 RootDirectoryEntries;
  u16 TotalSectors;
  u8 MediaDescriptor;
  u16 SectorsPerFat;
  u16 SectorsPerTrack; // Little Endian
  u16 Heads;
  u32 HiddenSectors;
  u32 TotalSectorsBig;

  // EBR
  u8 DriveNumber;
  u8 Reserved;
  u8 Signature;
  u32 SerialNumber;
  u8 VolumeLabel[11];
  u8 SystemIdentifier[8];
  // Boot code would be here, but we don't need it since
  // we are just reading the BPB

} __attribute__((packed)) BIOSParameterBlock;

//
//  http://web.archive.org/web/20170112194555/http://www.viralpatel.net/taj/tutorial/fat.php
//
typedef struct {
  u8 FileName[11];
  u8 Attributes;
  u8 Reserved;
  u8 CreateTimeTenth;
  u16 CreateTime;
  u16 CreateDate;
  u16 AccessTime;
  u16 FirstClusterHigh;
  u16 WriteTime;
  u16 WriteDate;
  u16 FirstClusterLow;
  u32 FileSize;
} __attribute__((packed)) FATEntry;

BIOSParameterBlock bpb;
u8 *fatBuffer;
FATEntry *rootDirectory;
u32 rootDirectoryEnd;

/**
 * @brief Checks if a disk image has a valid boot sector
 * @param disk A file pointer to the disk image
 * @return true if the disk image has a valid boot sector, false otherwise
 */
bool hasBootSector(FILE *disk) {
  return fread(&bpb, sizeof(BIOSParameterBlock), 1, disk) > 0;
}

/**
 * @brief Checks to see if a sector can be read on the dsik
 * @param disk A file pointer to the disk image
 * @param sectorNumber The sector number to read from
 * @param count The number of sectors to read
 * @param bufferOut A void* buffer to store the read data in
 * @return true if the read was successful, false otherwise
 */
bool canReadSector(FILE *disk, u32 sectorNumber, u32 count, void *bufferOut) {
  bool success = true;
  success = success &&
            (fseek(disk, sectorNumber * bpb.BytesPerSector, SEEK_SET) == 0);
  success =
      success && (fread(bufferOut, bpb.BytesPerSector, count, disk) == count);
  return success;
}

/**
 * @brief Reads the FAT table
 * @param disk A file pointer to the disk image
 * @return true if the FAT table was successfully read, false otherwise
 */
bool canReadFat(FILE *disk) {
  fatBuffer = (u8 *)malloc(bpb.SectorsPerFat * bpb.BytesPerSector);
  return canReadSector(disk, bpb.ReservedSectors, bpb.SectorsPerFat, fatBuffer);
}

/**
 * @brief Checks to see if a root directory can be read on the disk
 * @param disk A file pointer to the disk image
 * @return true if the root directory was successfully read, false otherwise
 */
bool canReadRootDirectory(FILE *disk) {
  u32 sectorNumber = bpb.ReservedSectors + bpb.SectorsPerFat * bpb.FatCount;
  u32 size = sizeof(FATEntry) * bpb.RootDirectoryEntries;
  u32 sectors = (size / bpb.BytesPerSector);

  // Round up
  if (size % bpb.BytesPerSector > 0) {
    sectors++;
  }

  rootDirectoryEnd = sectorNumber + sectors;
  rootDirectory = (FATEntry *)malloc(sectors * bpb.BytesPerSector);
  return canReadSector(disk, sectorNumber, sectors, rootDirectory);
}

/**
 * @brief Finds a file in the FAT root directory
 * @param name The name of the file to search for
 * @return A FATEntry* pointing to the file if found, NULL if not
 */
FATEntry *findFile(const char *name) {
  for (u32 i = 0; i < bpb.RootDirectoryEntries; i++) {
    if (memcmp(name, rootDirectory[i].FileName, 11) == 0) {
      return &rootDirectory[i];
    }
  }

  return NULL;
}

bool canReadFile(FATEntry *file, FILE *disk, u8 *bufferOut) {
  bool success = true;

  u16 currentCluster = file->FirstClusterLow;

  while ((success && currentCluster < 0xFFF8)) {
    // Calculate the sector to read from
    u32 sector = rootDirectoryEnd + (currentCluster - 2) * bpb.SectorsPerCluster;
    success = success && (canReadSector(disk, sector, bpb.SectorsPerCluster, bufferOut));
    bufferOut += bpb.SectorsPerCluster * bpb.BytesPerSector;

    // Get the next cluster from the FAT16 table
    u32 index = currentCluster * 2; // FAT16 entries are 2 bytes per cluster
    currentCluster = *(u16 *)(fatBuffer + index);

    // Check if the next cluster is the end of the chain
    if (currentCluster >= 0xFFF8) // EOF marker for FAT16
    {
      break;
    }
  }

  return success;
}

int main(int argc, char **argv) {
  if (argc < 3) {
    printf("Usage: %s <disk image> <filename>\n", argv[0]);
    return -1;
  }

  FILE *diskImage;
  fopen_s(&diskImage, argv[1], "rb");

  if (!diskImage) {
    printf("Failed to open disk image %s.\n", argv[1]);
    return -1;
  }
  printf("Successfully opened disk image %s.\n", argv[1]);

  if (!hasBootSector(diskImage)) {
    printf("Could not find boot sector in disk image %s.\n", argv[1]);
    return -2;
  }
  printf("Found boot sector in disk image %s.\n", argv[1]);

  if (!canReadFat(diskImage)) {
    printf("Could not read FAT from disk image %s.\n", argv[1]);
    free(fatBuffer);
    return -3;
  }
  printf("Read FAT from disk image %s.\n", argv[1]);

  if (!canReadRootDirectory(diskImage)) {
    printf("Could not read root directory from disk image %s.\n", argv[1]);
    free(fatBuffer);
    free(rootDirectory);
    return -4;
  }
  printf("Read root directory from disk image %s.\n", argv[1]);

  FATEntry *file = findFile(argv[2]);
  if (!file) {
    printf("Could not find file %s in root directory.\n", argv[2]);
    free(fatBuffer);
    free(rootDirectory);
    return -5;
  }
  printf("Found file %s in root directory.\n", argv[2]);

  u8 *buffer = (u8 *)malloc(file->FileSize + bpb.BytesPerSector);

  if (!canReadFile(file, diskImage, buffer)) {
    printf("Could not read file %s from disk image %s.\n", argv[2], argv[1]);
    free(fatBuffer);
    free(rootDirectory);
    free(buffer);
    return -6;
  }
  printf("Read file %s from disk image %s.\n", argv[2], argv[1]);

  puts("File contents:\n");

  for (size_t i = 0; i < file->FileSize; i++) {
    if (isprint(buffer[i])) {
      putc(buffer[i], stdout);
    } else {
      printf("<%02X>", buffer[i]);
    }
  }
  printf("\n");

  free(buffer);
  free(fatBuffer);
  free(rootDirectory);
  return 0;
}