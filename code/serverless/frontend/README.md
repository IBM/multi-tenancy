# frontend

### 1) Run local
```sh
cd frontend
npm install
```

#### a. Compiles and hot-reloads for development
```sh
cd frontend
npm run serve
```

#### b. Compiles and minifies for production
```sh
cd frontend
npm run build
```

#### c. Open browser

```sh
open http://localhost:8080
```

#### d. insert User and passwords

thomas@example.com / thomas4appid
alice@example.com / alice4appid

### 2) Setup and run containerized version

#### a. Login to Quay
```sh
cd frontend
docker login quay.io
```

#### b. Save your repostitory name in the environment variable
```sh
export MY_REPOSITORY=
```

#### c. Run the bash script
```
bash build_and_push_quay.sh
```

#### d. Open browser

```sh
open http://localhost:8080
```

#### e. insert User and passwords

thomas@example.com / thomas4appid
alice@example.com / alice4appid

![](./images/frontend-in-container.png)

