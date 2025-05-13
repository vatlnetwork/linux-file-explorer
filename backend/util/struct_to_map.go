package util

import "reflect"

func StructToMap(inputStruct any) map[string]any {
	result := make(map[string]any)
	val := reflect.ValueOf(inputStruct)

	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	for i := 0; i < val.NumField(); i++ {
		field := val.Type().Field(i)
		fieldValue := val.Field(i).Interface()
		result[field.Name] = fieldValue
	}

	return result
}
