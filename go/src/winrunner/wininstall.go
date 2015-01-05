// +build windows

package main

import (
	"code.google.com/p/winsvc/eventlog"
	"code.google.com/p/winsvc/mgr"
	"fmt"
	"os"
	"path/filepath"
)

func exePath() (string, error) {
	prog := os.Args[0]
	p, err := filepath.Abs(prog)
	if err != nil {
		return "", err
	}
	fi, err := os.Stat(p)
	if err == nil {
		if !fi.Mode().IsDir() {
			return p, nil
		}
		err = fmt.Errorf("%s is directory", p)
	}
	if filepath.Ext(p) == "" {
		p += ".exe"
		fi, err := os.Stat(p)
		if err == nil {
			if !fi.Mode().IsDir() {
				return p, nil
			}
			err = fmt.Errorf("%s is directory", p)
		}
	}
	return "", err
}

func installService(name, desc, configPath string) error {
	exepath, err := exePath()
	if err != nil {
		return err
	}
	if configPath != "" {
		exepath = exepath + " " + configPath
	}
	m, err := mgr.Connect()
	if err != nil {
		return err
	}
	defer m.Disconnect()
	s, err := m.OpenService(name)
	if err == nil {
		s.Close()
		return fmt.Errorf("service %s already exists", name)
	}
	s, err = m.CreateService(name, exepath, mgr.Config{DisplayName: desc, Description: desc, StartType: mgr.StartAutomatic})
	if err != nil {
		return err
	}
	defer s.Close()
	err = eventlog.InstallAsEventCreate(name, eventlog.Error|eventlog.Warning|eventlog.Info)
	if err != nil {
		s.Delete()
		return fmt.Errorf("SetupEventLogSource() failed: %s", err)
	}
	return nil
}

func removeService(name string) error {
	serviceMissing, err := deleteService(name);

	// Attempt to delete the event source if there
	// was no error deleting the service or the service
	// was missing.  If we don't delete the event source
	// registry key, the install will fail when it tries
	// to setup the registry key.
	if err == nil || serviceMissing {
		esErr := deleteServiceEventSource(name); 

		if err == nil {
			err = esErr
		}
	}

	return err;
}

func deleteService(name string) (serviceMissing bool, err error) {
	serviceMissing = false;

	m, err := mgr.Connect()
	if err != nil {
		return serviceMissing, err;
	}
	defer m.Disconnect()

	s, err := m.OpenService(name)
	if err != nil {
		serviceMissing = true;
		return serviceMissing, fmt.Errorf("service %s is not installed", name)
	}
	defer s.Close()

	err = s.Delete()
	if err != nil {
		return serviceMissing, err
	}

	return serviceMissing, nil;
}

func deleteServiceEventSource(name string) error {
	err := eventlog.Remove(name)
	if err != nil {
		return fmt.Errorf("RemoveEventLogSource() failed: %s", err)
	}
	return nil
} 

