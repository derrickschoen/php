---
# Docker Image for PHP Examples
---
### Summary
To simplify the running of the PHP examples, the Dockerfile will build an image and install the rosette-api library from the *local development source*.

### Basic Usage
Build the docker image, e.g. `docker build -t basistech/php:1.1 .`

Run an example as `docker run -e API_KEY=api-key -v "path-to-php-dir:/source" basistech/php:1.1`

To test against a specific source file, add `-e FILENAME=filename` before the `-v`, to test against an alternate url, add `-e ALT_URL=alternate_url`.