package domain

type FileSystemEntity interface {
	GetName() string
	GetPath() string
	GetSize() int64
	IsDirectory() bool
}
