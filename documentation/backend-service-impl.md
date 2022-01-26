## Implementation of the Backend Microservice

You can find the implementation of the backend service in the [multi-tenancy-backend](https://github.com/IBM/multi-tenancy-backend) repo.

The service has been developed with Quarkus:

* [Dependencies](https://github.com/IBM/multi-tenancy-backend/blob/main/pom.xml) managed via Maven
* [REST Endpoints via Rest Easy](https://github.com/IBM/multi-tenancy-backend/blob/main/src/main/java/com/ibm/catalog/CategoryResource.java)
    * http://localhost:8081/category is protected and will return a response code '401' not authorized
    * http://localhost:8081/category/2/products is not protected and will return data from Postgres
    * [Authentication Implementation](https://github.com/IBM/multi-tenancy-backend/blob/1b4aea1ac5504866cb8996f229903f2ad96ac294/src/main/resources/application.properties#L38-L43)
* [Persistence via Hibernate](https://github.com/IBM/multi-tenancy-backend/blob/main/src/main/java/com/ibm/catalog/Category.java)
* The backend service uses different databases for different tenants as well as different AppID service instances
* The Postgres and AppID instances need to be created first and they need to be configured (e.g. test users, sample data)
* [Configuration of Postgres and AppID](https://github.com/IBM/multi-tenancy-backend/blob/main/src/main/resources/application.properties)
* Check out these [local development](local-development.md) instructions how to develop, run and debug the backend and frontend services locally
* The application runs on port 8081
* CORS is enabled
