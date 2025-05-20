package domain

type FileSystemService interface {
	WalkDirectory(path string) ([]FileSystemEntity, error)
}
