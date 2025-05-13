package srverr

type SrvErr interface {
	IsSrvErr() bool
}

type ServerError struct {
	Message string
	Code    int
}

func New(message string, code ...int) ServerError {
	actualCode := 500
	if len(code) > 0 {
		actualCode = code[0]
	}

	return ServerError{
		Message: message,
		Code:    actualCode,
	}
}

func Wrap(err error, code ...int) ServerError {
	actualCode := 500
	if len(code) > 0 {
		actualCode = code[0]
	}

	return ServerError{
		Message: err.Error(),
		Code:    actualCode,
	}
}

func (e ServerError) Error() string {
	return e.Message
}

func (e ServerError) IsSrvErr() bool {
	return true
}
