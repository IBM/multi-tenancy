package org.acme.hibernate.orm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.jboss.logging.Logger;
import org.jboss.resteasy.annotations.jaxrs.PathParam;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.transaction.Transactional;
import javax.ws.rs.*;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;
import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
@Produces("application/json")
@Consumes("application/json")
@Path("/")
public class ProductResource {

    private static final Logger LOGGER = Logger.getLogger(ProductResource.class.getName());

    @Inject
    EntityManager entityManager;

    @GET
    @Path("product")
    public Product[] getDefault() {
        return get();
    }

    @GET
    @Path("{tenant}/product")
    public Product[] getTenant() {
        return get();
    }

    private Product[] get() {
        return entityManager.createNamedQuery("Product.findAll", Product.class)
                .getResultList().toArray(new Product[0]);
    }

    @GET
    @Path("product/{id}")
    public Product getSingleDefault(@PathParam("id") Integer id) {
        return findById(id);
    }

    @GET
    @Path("{tenant}/product/{id}")
    public Product getSingleTenant(@PathParam("id") Integer id) {
        return findById(id);
    }

    @GET
    @Path("{tenant}/category/{id}/products")
    public ArrayList<Product> getProductsFromCategory(@PathParam("id") Integer id) {

        List<ProductCategory> queryProductCategory =
                entityManager.createNamedQuery("ProductCategory.findByCategoryId")
                        .setParameter("categoryid", id)
                        .getResultList();

        LOGGER.info("queryProductCategory Size: " + queryProductCategory.size());
        LOGGER.info("categoryid: " + id);

        ArrayList<Product> products = new ArrayList<Product>();

        for (ProductCategory productCategoryTemp : queryProductCategory) {

            List<Product> queryProduct =
                    entityManager.createNamedQuery("Product.findById")
                            .setParameter("id", productCategoryTemp.getProductid())
                            .getResultList();

            LOGGER.info("queryProduct Size: " + queryProduct.size());


            products.add(queryProduct.get(0));

        }

        return products;

        //ProductCategory productCategory = new ProductCategory();
        //ProductCategory.getNamedQuery("findByCategoryId");
        //return findById(id);
    }

    private Product findById(Integer id) {
        Product entity = entityManager.find(Product.class, id);
        if (entity == null) {
            throw new WebApplicationException("Product with id of " + id + " does not exist.", 404);
        }
        return entity;
    }

    @POST
    @Transactional
    @Path("product")
    public Response createDefault(Product product) {
        return create(product);
    }

    @POST
    @Transactional
    @Path("{tenant}/product")
    public Response createTenant(Product product) {
        return create(product);
    }

    private Response create(Product product) {
        if (product.getId() != null) {
            throw new WebApplicationException("Id was invalidly set on request.", 422);
        }
        LOGGER.debugv("Create {0}", product.getName());
        entityManager.persist(product);
        return Response.ok(product).status(201).build();
    }

    @PUT
    @Path("product/{id}")
    @Transactional
    public Product updateDefault(@PathParam("id") Integer id, Product product) {
        return update(id, product);
    }

    @PUT
    @Path("{tenant}/product/{id}")
    @Transactional
    public Product updateTenant(@PathParam("id") Integer id, Product product) {
        return update(id, product);
    }

    public Product update(@PathParam Integer id, Product product) {
        if (product.getName() == null) {
            throw new WebApplicationException("Product Name was not set on request.", 422);
        }

        Product entity = entityManager.find(Product.class, id);
        if (entity == null) {
            throw new WebApplicationException("Product with id of " + id + " does not exist.", 404);
        }
        entity.setName(product.getName());

        LOGGER.debugv("Update #{0} {1}", product.getId(), product.getName());

        return entity;
    }

    @DELETE
    @Path("product/{id}")
    @Transactional
    public Response deleteDefault(@PathParam("id") Integer id) {
        return delete(id);
    }

    @DELETE
    @Path("{tenant}/product/{id}")
    @Transactional
    public Response deleteTenant(@PathParam("id") Integer id) {
        return delete(id);
    }

    public Response delete(Integer id) {
        Product product = entityManager.getReference(Product.class, id);
        if (product == null) {
            throw new WebApplicationException("Product with id of " + id + " does not exist.", 404);
        }
        LOGGER.debugv("Delete #{0} {1}", product.getId(), product.getName());
        entityManager.remove(product);
        return Response.status(204).build();
    }

    @GET
    @Path("productFindBy")
    public Response findByDefault(@QueryParam("type") String type, @QueryParam("value") String value) {
        return findBy(type, value);
    }

    @GET
    @Path("{tenant}/productFindBy")
    public Response findByTenant(@QueryParam("type") String type, @QueryParam("value") String value) {
        return findBy(type, value);
    }

    private Response findBy(String type, String value) {
        if (!"name".equalsIgnoreCase(type)) {
            throw new IllegalArgumentException("Currently only 'productFindBy?type=name' is supported");
        }
        List<Product> list = entityManager.createNamedQuery("Product.findByName", Product.class).setParameter("name", value).getResultList();
        if (list.size() == 0) {
            return Response.status(404).build();
        }
        Product product = list.get(0);
        return Response.status(200).entity(product).build();
    }

    @Provider
    public static class ErrorMapper implements ExceptionMapper<Exception> {

        @Inject
        ObjectMapper objectMapper;

        @Override
        public Response toResponse(Exception exception) {
            LOGGER.error("Failed to handle request", exception);

            int code = 500;
            if (exception instanceof WebApplicationException) {
                code = ((WebApplicationException) exception).getResponse().getStatus();
            }

            ObjectNode exceptionJson = objectMapper.createObjectNode();
            exceptionJson.put("exceptionType", exception.getClass().getName());
            exceptionJson.put("code", code);

            if (exception.getMessage() != null) {
                exceptionJson.put("error", exception.getMessage());
            }

            return Response.status(code)
                    .entity(exceptionJson)
                    .build();
        }

    }
}
