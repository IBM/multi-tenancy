package postgresHelper

import (
	"context"
	b64 "encoding/base64"
	"encoding/json"
	"io"
	"net/http"

	pgx "github.com/jackc/pgx/v4"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

type GitHubFile struct {
	Name         string
	Path         string
	Sha          string
	Size         uint64
	Url          string
	Html_url     string
	Git_url      string
	Download_url string
	Type         string
	Content      string
}

type GitHubFileError struct {
	Message           string
	Documentation_url string
}

func CreateExampleDatabase(DATABASE_URL string, ctx context.Context) (error, bool) {
	log := log.FromContext(ctx)
	var sDecFileContent []byte
	var sDecFileContentError []byte
	postgresTableExists := false

	// ****************************
	// Get file with statements from GitHub

	// 1. Create HTTP request "github"
	req, err := http.NewRequest("GET", "https://api.github.com/repos/IBM/multi-tenancy/contents/installapp/postgres-config/create-populate-tenant-a.sql", nil)
	if err != nil {
		log.Error(err, "Create request")
		return err, postgresTableExists
	}

	// 2. Define header
	req.Header.Set("Accept", "application/json")

	// 3. Create client
	client := http.Client{}

	// 4. Invoke HTTP request
	resp, err := client.Do(req)
	if err != nil {
		log.Error(err, "Invoke request")
		return err, postgresTableExists
	}

	defer resp.Body.Close()

	// 5. Verify the request status
	if resp.StatusCode == http.StatusOK {

		// 6. Get only body from response
		bodyBytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error(err, "No response form request")
			return err, postgresTableExists
		}

		// 7. Convert body to json content
		var dat GitHubFile
		var datError GitHubFileError
		if err := json.Unmarshal(bodyBytes, &dat); err != nil {
			log.Error(err, "Panic")
			return err, postgresTableExists
		}

		if err := json.Unmarshal(bodyBytes, &datError); err != nil {
			log.Error(err, "Panic")
			return err, postgresTableExists
		}

		// 8. Extract and decode file content from json
		sDecFileContent, _ = b64.StdEncoding.DecodeString(dat.Content)
		sDecFileContentError, _ = b64.StdEncoding.DecodeString(datError.Message)
	}

	// 9. Connect to a database
	conn, err := pgx.Connect(context.Background(), DATABASE_URL)
	if err != nil {
		log.Error(err, "Unable to connect to database "+DATABASE_URL+"\n")
		return err, postgresTableExists
	} else {
		log.Info("Connected to the DB: true [" + DATABASE_URL + "] \n")
	}

	// 10. Create a sql statements from file content

	statement := string(sDecFileContent)
	contentError := string(sDecFileContentError)
	log.Info("GitHub file content statement : [" + statement + "] and Info [" + contentError + "]")
	_, err = conn.Exec(context.Background(), statement)

	if err != nil {
		log.Error(err, "File content for the statement")
		return err, postgresTableExists
	} else {
		log.Info("File content for the statement: true\n")
		postgresTableExists = true
	}

	// 11. Verify the created tables with a query
	var name string
	var price float64

	if postgresTableExists {
		err = conn.QueryRow(context.Background(), "select name, price from product where name='Return of the Jedi'").Scan(&name, &price)
		if err != nil {
			log.Info("Connected to the DB: true\n")
			log.Error(err, "QueryRow failed\n")
			return err, postgresTableExists
		} else {
			log.Info("Return values of the table: ", name, price)
		}
	}

	defer conn.Close(context.Background())
	log.Info("**********Database done********")

	return nil, postgresTableExists
}
