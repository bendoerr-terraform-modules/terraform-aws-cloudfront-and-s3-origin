package test_test

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	"github.com/gruntwork-io/terratest/modules/random"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/kr/pretty"
)

func TestDefaults(t *testing.T) {
	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/simple"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		NoColor:      os.Getenv("CI") == "true",
		Vars: map[string]interface{}{
			"namespace": strings.ToLower(random.UniqueId()),
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Print out the Terraform Output values
	_, _ = pretty.Print(terraform.OutputAll(t, terraformOptions))

	// AWS Session
	cfg, err := config.LoadDefaultConfig(
		context.Background(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

	// Upload two test files to the S3 bucket
	s3Client := s3.NewFromConfig(cfg)
	bucketID := terraform.Output(t, terraformOptions, "s3_bucket_id")

	indexTxt := random.UniqueId()
	testTxt := random.UniqueId()

	_, err = s3Client.PutObject(
		context.Background(),
		&s3.PutObjectInput{
			Bucket: aws.String(bucketID),
			Key:    aws.String("index.html"),
			Body:   strings.NewReader(indexTxt),
		},
	)
	defer func() {
		_, derr := s3Client.DeleteObject(
			context.Background(),
			&s3.DeleteObjectInput{
				Bucket: aws.String(bucketID),
				Key:    aws.String("index.html"),
			})
		if derr != nil {
			t.Log("failed to delete index.html")
			t.Log(derr)
		} else {
			t.Log("deleted index.html")
		}
	}()
	if err != nil {
		t.Fatal(err)
	}

	_, err = s3Client.PutObject(
		context.Background(),
		&s3.PutObjectInput{
			Bucket: aws.String(bucketID),
			Key:    aws.String("test.txt"),
			Body:   strings.NewReader(testTxt),
		},
	)
	defer func() {
		_, derr := s3Client.DeleteObject(
			context.Background(),
			&s3.DeleteObjectInput{
				Bucket: aws.String(bucketID),
				Key:    aws.String("test.txt"),
			})
		if derr != nil {
			t.Log("failed to delete test.txt")
			t.Log(derr)
		} else {
			t.Log("deleted test.txt")
		}
	}()
	if err != nil {
		t.Fatal(err)
	}

	// Ensure that the distribution is ready
	cloudfrontClient := cloudfront.NewFromConfig(cfg)
	cloudfrontID := terraform.Output(t, terraformOptions, "cloudfront_distribution_id")

	ready := false

	// Wait 10 Minutes max
	for wait := 0; wait < 60; wait++ {
		output, lerr := cloudfrontClient.GetDistribution(context.Background(), &cloudfront.GetDistributionInput{
			Id: aws.String(cloudfrontID),
		})
		if lerr != nil {
			t.Fatal(lerr)
		}

		t.Log("Current distribution status: " + *output.Distribution.Status)

		if *output.Distribution.Status == "Deployed" {
			ready = true
			break
		}

		time.Sleep(10 * time.Second)
	}

	if !ready {
		t.Fatal("timeout: Distribution is not ready")
	}

	// Make test HTTPS requests
	defaultDomainName := terraform.Output(t, terraformOptions, "cloudfront_distribution_domain_name")
	aliasDomainName := terraform.Output(t, terraformOptions, "cloudfront_distribution_alias_domain_name")
	names := []string{defaultDomainName, aliasDomainName}

	for _, domainName := range names {
		// Test the / default
		indexResp := httpGetBodyWithRetry(t, fmt.Sprintf("https://%s/", domainName))
		if indexTxt != string(indexResp) {
			t.Fatal(makediff(indexTxt, string(indexResp)))
		} else {
			t.Log("success GET index.html")
		}

		// Test the /text.txt
		textResp := httpGetBodyWithRetry(t, fmt.Sprintf("https://%s/test.txt", domainName))
		if testTxt != string(textResp) {
			t.Fatal(makediff(testTxt, string(textResp)))
		} else {
			t.Log("success GET test.txt")
		}
	}
}

// httpGetBodyWithRetry GETs url and returns the response body, retrying on error
// for up to ~5 minutes. The alias domain is a freshly-created Route53 record, so
// its DNS may not have propagated when the test runs and the request can
// transiently fail to resolve; poll instead of failing on the first miss (same
// manual-poll style used above to wait for the distribution to deploy). Each
// attempt is bounded by a client timeout so a stalled connect can't hang the loop.
func httpGetBodyWithRetry(t *testing.T, url string) []byte {
	t.Helper()
	client := &http.Client{Timeout: 10 * time.Second}
	for range 30 {
		resp, err := client.Get(url)
		if err != nil {
			t.Logf("GET %s not ready yet (%v); retrying", url, err)
			time.Sleep(10 * time.Second)
			continue
		}

		body, rerr := io.ReadAll(resp.Body)
		resp.Body.Close()
		if rerr != nil {
			t.Fatal(rerr)
		}
		return body
	}

	t.Fatalf("timeout: GET %s never succeeded", url)
	return nil
}

func makediff(want interface{}, got interface{}) string {
	s := fmt.Sprintf("\nwant: %# v", pretty.Formatter(want))
	s = fmt.Sprintf("%s\ngot: %# v", s, pretty.Formatter(got))
	diffs := pretty.Diff(want, got)
	s += "\ndifferences: "
	for _, d := range diffs {
		s = fmt.Sprintf("%s\n  - %s", s, d)
	}
	return s
}
