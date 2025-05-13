package mongo

import "fmt"

type Config struct {
	Hostname string
	Database string
	Username string
	Password string
}

func (c Config) ConnectionString() string {
	authAndHost := c.Hostname
	if c.UsingAuth() {
		authAndHost = fmt.Sprintf("%v:%v@%v", c.Username, c.Password, c.Hostname)
	}
	return fmt.Sprintf("mongodb://%v/%v", authAndHost, c.Database)
}

func (c Config) IsEnabled() bool {
	return c.Hostname != "" && c.Database != ""
}

func (c Config) UsingAuth() bool {
	return c.Username != "" && c.Password != ""
}
