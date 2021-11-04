package com.ibm.catalog.testing;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;

@QuarkusTest
public class ProductResourceTest {

    // TENANT-A Products
    @Test
    public void testCategoryEndpoint() {
        given()
                .when().get("/base/productcategory/1")
                .then()
                .statusCode(200);

    }


}