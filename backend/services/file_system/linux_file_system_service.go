package filesystemrepo

import (
	"golang-web-core/domain"
	"os"
)

type LinuxFileSystemService struct {
}

func (l *LinuxFileSystemService) readFiles(path string) ([]domain.FileSystemEntity, error) {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var entities []domain.FileSystemEntity
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			return nil, err
		}

		if entry.IsDir() {
			folder := domain.Folder{
				Name:         info.Name(),
				CreatedAt:    info.ModTime(),
				LastModified: info.ModTime(),
				Size:         info.Size(),
				Path:         path + "/" + info.Name(),
			}
			entities = append(entities, folder)

			// Recursively read subdirectories
			subEntities, err := l.readFiles(path + "/" + info.Name())
			if err != nil {
				return nil, err
			}
			entities = append(entities, subEntities...)
		} else {
			file := domain.File{
				Name:         info.Name(),
				CreatedAt:    info.ModTime(),
				LastModified: info.ModTime(),
				Size:         info.Size(),
				Path:         path + "/" + info.Name(),
				Extension:    l.getExtension(info.Name()),
			}
			entities = append(entities, file)
		}
	}
	return entities, nil
}

func (l *LinuxFileSystemService) getExtension(filename string) string {
	for i := len(filename) - 1; i >= 0; i-- {
		if filename[i] == '.' {
			return filename[i:]
		}
	}
	return ""
}
