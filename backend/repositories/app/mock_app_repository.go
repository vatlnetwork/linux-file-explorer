package apprepo

import "golang-web-core/domain"

type MockAppRepository struct {
}

// GetAllApps implements domain.AppRepository.
func (m MockAppRepository) GetAllApps() ([]domain.App, error) {
	return []domain.App{
		{
			Name:       "Test App",
			IconPath:   "test.png",
			BinaryPath: "/usr/bin/test",
		},
		{
			Name:       "Test App 2",
			IconPath:   "test2.png",
			BinaryPath: "/usr/bin/test2",
		},
		{
			Name:       "Test App 3",
			IconPath:   "test3.png",
			BinaryPath: "/usr/bin/test3",
		},
	}, nil
}

var _ domain.AppRepository = MockAppRepository{}
