package domain

type FileAssociationRepository interface {
	GetAllAssociations() ([]FileAssociation, error)
	CreateAssociation(association FileAssociation) (FileAssociation, error)
	DeleteAssociation(id string) error
}
