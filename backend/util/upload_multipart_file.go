package util

import (
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

type UploadMultipartFileResponse struct {
	Path      string `json:"path"`
	FileName  string `json:"fileName"`
	FileType  string `json:"fileType"`
	Extension string `json:"extension"`
}

func UploadMultipartFile(file *multipart.FileHeader, uploadsDir string) (UploadMultipartFileResponse, error) {
	fileName := file.Filename
	fileType := file.Header.Get("Content-Type")
	extension := filepath.Ext(fileName)

	uploadFileName := uuid.NewString()

	uploadFileName = fmt.Sprintf("%s%s", uploadFileName, extension)

	uploadFile, err := os.Create(filepath.Join(uploadsDir, uploadFileName))
	if err != nil {
		return UploadMultipartFileResponse{}, err
	}
	defer uploadFile.Close()

	fileReader, err := file.Open()
	if err != nil {
		return UploadMultipartFileResponse{}, err
	}

	_, err = uploadFile.ReadFrom(fileReader)
	if err != nil {
		return UploadMultipartFileResponse{}, err
	}

	response := UploadMultipartFileResponse{
		Path:      uploadFileName,
		FileName:  fileName,
		FileType:  fileType,
		Extension: extension,
	}

	return response, nil
}
