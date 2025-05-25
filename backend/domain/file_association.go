package domain

type FileAssociation struct {
	Id            string `json:"id"`
	FileExtension string `json:"fileExtension"`
	BinaryPath    string `json:"binaryPath"`
}
