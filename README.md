<h1 align = "center"> Beancount Fava Docker Service </h1>

<p align="center">
    <img src="https://github.com/ArthurFDLR/fava-service/blob/master/.github/nord-theme.png?raw=true" alt="Banner" width="100%" style="border-radius: 5px;">
</p>

## Installation

### Build the Docker image

1. Set the port for the Fava service in the [`nginx.conf`](./nginx.conf) file (`80` by default):
    ```nginx.conf
    ...
        server {
            listen 80;
    ...
    ```

2. Set new credentials (User: `admin` & Password: `admin` by default):
    ```sh
    htpasswd -c .htpasswd <user>
    ```

3. [Optional] Customize the Fava theme by editing the [`style.css`](./style.css) file. Or, if you want to use the default Fava theme, comment the following line in the [`Dockerfile`](./Dockerfile) file:
    ```Dockerfile
    # Comment the following line to use the default Fava theme
    COPY ./style.css ./fava/frontend/css/style.css
    ```

4. Build the Docker image:
    ```sh
    docker build -t fava-service .
    ```

    > **Note:** You can change the name of the image (`fava-service`) to whatever you want.

### Run the Docker container

1. Set the URL to your Ledger repository as (1.) an environment variable, **OR** (2.) a Docker secret:
   1. Set `REPOSITORY_URL` to the URL of your Ledger repository in [`example/user.conf`](./example/user.conf):
        ```sh
        echo "REPOSITORY_URL=https://git.server/ledger.git" >> ./example/user.conf
        ```
   2. Update [`example/ledger-git`](`./example/ledger-git`) to use the URL of your Ledger repository:
        ```sh
        echo -n "https://<user>:<password>@git.server/ledger.git" > ./example/ledger-git
        ```
    > **Note:** The environment variable `REPOSITORY_URL` has priority over the Docker secret `ledger-git` if both are set.

2. Set `BEAN_FILE` to the path of your main Beancount file in your Ledger repository in [`example/user.conf`](./example/user.conf). Do not use trailing slashes. For example:
    ```sh
    echo "BEAN_FILE=main.beancount" >> ./example/user.conf
    echo "BEAN_FILE=my-ledger/main.beancount" >> ./example/user.conf
    ```

3. Start the Docker service:
    ```sh
    docker compose -f example/docker-compose.yml up
    ```
