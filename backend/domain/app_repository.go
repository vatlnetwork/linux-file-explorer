package domain

type AppRepository interface {
	GetAllApps() ([]App, error)
}
