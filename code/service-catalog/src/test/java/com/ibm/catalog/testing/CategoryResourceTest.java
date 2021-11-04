package com.ibm.catalog.testing;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class CategoryResourceTest {

    // TENANT-A Catagories
    @Test
    public void testCategoryEndpoint() {
        given()
                .when().get("/base/category")
                .then()
                .statusCode(200);

    }


}