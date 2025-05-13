package util

import (
	"reflect"
	"testing"
)

func TestStructToMap(t *testing.T) {
	type SimpleStruct struct {
		Name string
		Age  int
	}

	type NestedStruct struct {
		ID     int
		Simple SimpleStruct
		Tags   []string
	}

	testCases := []struct {
		name     string
		input    any
		expected map[string]any
	}{
		{
			name:     "Simple Struct",
			input:    SimpleStruct{Name: "Alice", Age: 30},
			expected: map[string]any{"Name": "Alice", "Age": 30},
		},
		{
			name:     "Empty Struct",
			input:    struct{}{},
			expected: map[string]any{},
		},
		{
			name:     "Pointer to Simple Struct",
			input:    &SimpleStruct{Name: "Bob", Age: 25},
			expected: map[string]any{"Name": "Bob", "Age": 25},
		},
		{
			name: "Struct with Nested Struct and Slice",
			input: NestedStruct{
				ID:     1,
				Simple: SimpleStruct{Name: "Charlie", Age: 35},
				Tags:   []string{"go", "test"},
			},
			expected: map[string]any{
				"ID":     1,
				"Simple": SimpleStruct{Name: "Charlie", Age: 35},
				"Tags":   []string{"go", "test"},
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := StructToMap(tc.input)
			if !reflect.DeepEqual(result, tc.expected) {
				t.Errorf("StructToMap(%#v) = %v; want %v", tc.input, result, tc.expected)
			}
		})
	}
}
