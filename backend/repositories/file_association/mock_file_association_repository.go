package fileassociation

import (
	"golang-web-core/domain"

	"github.com/google/uuid"
)

type MockFileAssociationRepository struct {
}

// CreateAssociation implements domain.FileAssociationRepository.
func (m MockFileAssociationRepository) CreateAssociation(association domain.FileAssociation) (domain.FileAssociation, error) {
	association.Id = uuid.New().String()

	return association, nil
}

// DeleteAssociation implements domain.FileAssociationRepository.
func (m MockFileAssociationRepository) DeleteAssociation(id string) error {
	return nil
}

// GetAllAssociations implements domain.FileAssociationRepository.
func (m MockFileAssociationRepository) GetAllAssociations() ([]domain.FileAssociation, error) {
	return []domain.FileAssociation{
		{
			Id:            uuid.New().String(),
			FileExtension: ".txt",
			BinaryPath:    "/usr/bin/nano",
		},
		{
			Id:            uuid.New().String(),
			FileExtension: ".md",
			BinaryPath:    "/usr/bin/nvim",
		},
		{
			Id:            uuid.New().String(),
			FileExtension: ".go",
			BinaryPath:    "/usr/bin/go",
		},
		{
			Id:            uuid.New().String(),
			FileExtension: ".py",
			BinaryPath:    "/usr/bin/python3",
		},
		{
			Id:            uuid.New().String(),
			FileExtension: ".sh",
			BinaryPath:    "/usr/bin/bash",
		},
	}, nil
}

var _ domain.FileAssociationRepository = MockFileAssociationRepository{}
