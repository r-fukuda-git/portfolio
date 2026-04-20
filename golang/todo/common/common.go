package common

import (
	"net/http"
	"strconv"
)

// string型からint型へ変換
func GetFormInt(r *http.Request, key string) (int, error) {
	str := r.FormValue(key)
	if str == "" {
		return 0, nil
	}
	return strconv.Atoi(str)
}

// string型からbool型へ変換
func GetFormBool(r *http.Request, key string) (bool, error) {
	strBool := r.FormValue(key)
	if strBool == "" {
		return false, nil
	}
	return strconv.ParseBool(strBool)
}
