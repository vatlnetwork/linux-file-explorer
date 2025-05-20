package domain

import "time"

type Folder struct {
	Name         string
	CreatedAt    time.Time
	LastModified time.Time
	Size         int64
	Path         string
}

func (f Folder) GetName() string {
	return f.Name
}

func (f Folder) GetPath() string {
	return f.Path
}

func (f Folder) GetSize() int64 {
	return f.Size
}

func (f Folder) IsDirectory() bool {
	return true
}
