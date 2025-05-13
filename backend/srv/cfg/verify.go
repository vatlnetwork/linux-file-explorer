package cfg

import "fmt"

func (c *Config) Verify() error {
	if c.Port == 0 {
		return fmt.Errorf("port is required")
	}

	if c.Env != Development && c.Env != Production {
		return fmt.Errorf("invalid environment: %v", c.Env)
	}

	if c.IsSSL() {
		err := c.SSL.SetCertPath(c.SSL.CertPath)
		if err != nil {
			return err
		}

		err = c.SSL.SetKeyPath(c.SSL.KeyPath)
		if err != nil {
			return err
		}
	}

	return nil
}
