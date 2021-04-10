package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strings"

	"github.com/shurcooL/githubv4"
	"golang.org/x/oauth2"
)

func init() {
	err := ioutil.WriteFile("input", []byte("{{SNAPSHOT_HASH}}"), 0666)
	if err != nil {
		panic(err)
	}
}

func main() {

	tags := getSortedTags()

	buffer := bytes.NewBuffer(nil)

	buffer.WriteString("flutter,oid,engine,dart,snapshot")

	defer func() {
		//fmt.Println(buffer.String())

		err := ioutil.WriteFile("snapshot-hash.csv", buffer.Bytes(), 0666)
		if err != nil {
			panic(err)
		}
	}()

	for i := range tags {
		comma := 0

		buffer.WriteString("\n")

		buffer.WriteString(tags[i].Node.Name)
		buffer.WriteString(",")
		comma++

		buffer.WriteString(tags[i].Node.Target.Oid)
		buffer.WriteString(",")
		comma++

		fmt.Println("tag", tags[i].Node.Name, tags[i].Node.Target.Oid, tags[i].Cursor)

		flutterEngineVersion, err := getFlutterEngineVersion(tags[i].Node.Target.Oid)
		if err != nil {
			fmt.Println(err)
			buffer.WriteString(fillCommas(comma))
			continue
		}

		buffer.WriteString(flutterEngineVersion)
		buffer.WriteString(",")
		comma++

		fmt.Println("tag", tags[i].Node.Name, "engine", flutterEngineVersion)

		dartVersion, err := getDartVersion(flutterEngineVersion)
		if err != nil {
			fmt.Println(err)
			buffer.WriteString(fillCommas(comma))
			continue
		}

		buffer.WriteString(dartVersion)
		buffer.WriteString(",")
		comma++

		fmt.Println("tag", tags[i].Node.Name, "dart", dartVersion)

		snapshotHash, err := getsnapshotHash(dartVersion)
		if err != nil {
			fmt.Println(err, snapshotHash)
			buffer.WriteString(fillCommas(comma))
			continue
		}

		buffer.WriteString(snapshotHash)

		fmt.Println("tag", tags[i].Node.Name, "snapshot", snapshotHash)
	}

}

func __FUNC__() string {
	pc := make([]uintptr, 10)
	if runtime.Callers(2, pc) < 1 {
		return ""
	}
	f := runtime.FuncForPC(pc[0])
	return f.Name()
}

func fillCommas(comma int) string {
	return strings.Repeat(",", 4-comma)
}

func getSortedTags() (result []struct {
	Cursor string
	Node   struct {
		Name   string
		Target struct {
			Oid string
		}
	}
}) {
	var refs struct {
		Repository struct {
			//Description string
			Refs struct {
				Edges []struct {
					Cursor string
					Node   struct {
						Name   string
						Target struct {
							Oid string
						}
					}
				}
			} `graphql:"refs(refPrefix: \"refs/tags/\", first: 100, after: $after, orderBy: {field: TAG_COMMIT_DATE, direction: DESC})"`
		} `graphql:"repository(owner: \"flutter\", name: \"flutter\")"`
	}

	ctx := context.Background()

	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv("GITHUB_ACCESS_TOKEN")},
	)
	tc := oauth2.NewClient(ctx, ts)
	clientv4 := githubv4.NewClient(tc) // for sorted refs

	after := os.Getenv("AFTER") // for debug
	for i := 0; i < 50; i++ {   // max times
		variables := map[string]interface{}{
			"after": githubv4.String(after),
		}
		err := clientv4.Query(context.Background(), &refs, variables)
		if err != nil {
			panic(err)
		}

		if len(refs.Repository.Refs.Edges) < 1 {
			break
		}

		after = refs.Repository.Refs.Edges[len(refs.Repository.Refs.Edges)-1].Cursor
		if after == "" {
			panic("empty cursor")
		}

		result = append(result, refs.Repository.Refs.Edges...)

	}

	return
}

func getsnapshotHash(dart_oid string) (string, error) {
	defer os.Remove("output")
	defer os.Remove(fmt.Sprintf("sdk-%s.zip", dart_oid))
	defer os.RemoveAll(fmt.Sprintf("sdk-%s", dart_oid))

	err := downloadDart(dart_oid)
	if err != nil {
		return "", err
	}

	cmd := exec.Command("unzip", "-qq", fmt.Sprintf("sdk-%s.zip", dart_oid))
	if runtime.GOOS == "windows" {
		cmd = exec.Command("wsl", "unzip", "-qq", fmt.Sprintf("sdk-%s.zip", dart_oid))
	}
	out, err := cmd.CombinedOutput()
	if err != nil {
		return string(out), err
	}

	body, _ := ioutil.ReadFile(fmt.Sprintf("sdk-%s/tools/make_version.py", dart_oid))
	bOld := strings.Index(string(body), "--format") == -1

	if bOld {
		// python sdk-7e72c9ae7ef128a28a9e9eb8bd3c46d955602999/tools/make_version.py -q --input input --output output
		cmd = exec.Command("python", fmt.Sprintf("sdk-%s/tools/make_version.py", dart_oid), "-q", "--input", "input", "--output", "output")
		if runtime.GOOS == "windows" {
			cmd = exec.Command("wsl", "python", fmt.Sprintf("sdk-%s/tools/make_version.py", dart_oid), "-q", "--input", "input", "--output", "output")
		}
	} else {
		// python dart/tools/make_version.py --no_git -q --format {{SNAPSHOT_HASH}}
		cmd = exec.Command("python", fmt.Sprintf("sdk-%s/tools/make_version.py", dart_oid), "--no_git", "-q", "--format", "{{SNAPSHOT_HASH}}")
		if runtime.GOOS == "windows" {
			cmd = exec.Command("wsl", "python", fmt.Sprintf("sdk-%s/tools/make_version.py", dart_oid), "--no_git", "-q", "--format", "{{SNAPSHOT_HASH}}")
		}
	}

	out, err = cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	if bOld {
		out, err = ioutil.ReadFile("output")
	}
	return string(out), nil
}

func downloadDart(dart_oid string) error {
	filename := fmt.Sprintf("sdk-%s.zip", dart_oid)

	out, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer out.Close()

	res, err := http.Get(fmt.Sprintf("https://github.com/dart-lang/sdk/archive/%s.zip", dart_oid))
	if err != nil {
		return err
	}
	defer res.Body.Close()

	_, err = io.Copy(out, res.Body)

	return err
}

func getDartVersion(flutter_engine_oid string) (string, error) {
	res, err := http.Get(fmt.Sprintf("https://github.com/flutter/engine/raw/%s/DEPS", flutter_engine_oid))
	if err != nil {
		return "", err
	}

	if res.StatusCode != http.StatusOK {
		err = fmt.Errorf("%s: status %d of %s", __FUNC__(), res.StatusCode, flutter_engine_oid)
		return "", err
	}

	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return "", err
	}

	m := regexp.MustCompile(`dart_revision[^\na-f\d]+([\da-f]{40})`).FindStringSubmatch(string(body))
	if len(m) != 2 {
		err = fmt.Errorf("%s: can not find match of %s", __FUNC__(), flutter_engine_oid)
		return "", err
	}

	return m[1], err
}

func getFlutterEngineVersion(flutter_oid string) (string, error) {
	res, err := http.Get(fmt.Sprintf("https://github.com/flutter/flutter/raw/%s/bin/internal/engine.version", flutter_oid))
	if err != nil {
		return "", err
	}

	if res.StatusCode != http.StatusOK {
		err = fmt.Errorf("%s: status %d of %s", __FUNC__(), res.StatusCode, flutter_oid)
		return "", err
	}

	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return "", err
	}

	body = bytes.ReplaceAll(body, []byte{'\n'}, nil)

	if len(body) == 0 {
		err = fmt.Errorf("%s: empty body of %s", __FUNC__(), flutter_oid)
	}

	return string(body), err
}
