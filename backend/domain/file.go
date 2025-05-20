package domain

import "time"

type File struct {
	Name         string
	CreatedAt    time.Time
	LastModified time.Time
	Size         int64
	Path         string
	Extension    string
}

func (f File) GetName() string {
	return f.Name
}

func (f File) GetPath() string {
	return f.Path
}

func (f File) GetSize() int64 {
	return f.Size
}

func (f File) IsDirectory() bool {
	return false
}
