package com.ibm.catalog;

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
import java.util.List;

// Security
import org.jboss.resteasy.annotations.cache.NoCache;

// Token
import org.eclipse.microprofile.jwt.JsonWebToken;
import io.quarkus.oidc.IdToken;
import io.quarkus.oidc.RefreshToken;
import javax.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
@Produces("application/json")
@Consumes("application/json")
@Path("/")
public class CategoryResource {

    private static final Logger LOGGER = Logger.getLogger(CategoryResource.class.getName());

    @Inject
    EntityManager entityManager;

    @GET
    @Path("category")
    public Category[] getDefault() {
        return get();
    }

    @GET
    @Path("{tenant}/category")
    public Category[] getTenant() {
        return get();
    }

    private Category[] get() {
        return entityManager.createNamedQuery("Category.findAll", Category.class)
                .getResultList().toArray(new Category[0]);
    }

    @GET
    @Path("category/{id}")
    public Category getSingleDefault(@PathParam("id") Integer id) {
        return findById(id);
    }

    @GET
    @Path("{tenant}/category/{id}")
    public Category getSingleTenant(@PathParam("id") Integer id) {
        return findById(id);
    }

    private Category findById(Integer id) {
        Category entity = entityManager.find(Category.class, id);
        if (entity == null) {
            throw new WebApplicationException("Category with id of " + id + " does not exist.", 404);
        }
        return entity;
    }

    @POST
    @Transactional
    @Path("category")
    public Response createDefault(Category category) {
        return create(category);
    }

    @POST
    @Transactional
    @Path("{tenant}/category")
    public Response createTenant(Category category) {
        return create(category);
    }

    private Response create(Category category) {
        if (category.getId() != null) {
            throw new WebApplicationException("Id was invalidly set on request.", 422);
        }
        LOGGER.debugv("Create {0}", category.getName());
        entityManager.persist(category);
        return Response.ok(category).status(201).build();
    }

    @PUT
    @Path("category/{id}")
    @Transactional
    public Category updateDefault(@PathParam("id") Integer id, Category category) {
        return update(id, category);
    }

    @PUT
    @Path("{tenant}/category/{id}")
    @Transactional
    public Category updateTenant(@PathParam("id") Integer id, Category category) {
        return update(id, category);
    }

    public Category update(@PathParam Integer id, Category category) {
        if (category.getName() == null) {
            throw new WebApplicationException("Category Name was not set on request.", 422);
        }

        Category entity = entityManager.find(Category.class, id);
        if (entity == null) {
            throw new WebApplicationException("Category with id of " + id + " does not exist.", 404);
        }
        entity.setName(category.getName());

        LOGGER.debugv("Update #{0} {1}", category.getId(), category.getName());

        return entity;
    }

    @DELETE
    @Path("category/{id}")
    @Transactional
    public Response deleteDefault(@PathParam("id") Integer id) {
        return delete(id);
    }

    @DELETE
    @Path("{tenant}/category/{id}")
    @Transactional
    public Response deleteTenant(@PathParam("id") Integer id) {
        return delete(id);
    }

    public Response delete(Integer id) {
        Category category = entityManager.getReference(Category.class, id);
        if (category == null) {
            throw new WebApplicationException("Category with id of " + id + " does not exist.", 404);
        }
        LOGGER.debugv("Delete #{0} {1}", category.getId(), category.getName());
        entityManager.remove(category);
        return Response.status(204).build();
    }

    @GET
    @Path("categoryFindBy")
    public Response findByDefault(@QueryParam("type") String type, @QueryParam("value") String value) {
        return findBy(type, value);
    }

    @GET
    @Path("{tenant}/categoryFindBy")
    public Response findByTenant(@QueryParam("type") String type, @QueryParam("value") String value) {
        return findBy(type, value);
    }

    private Response findBy(String type, String value) {
        if (!"name".equalsIgnoreCase(type)) {
            throw new IllegalArgumentException("Currently only 'categoryFindBy?type=name' is supported");
        }
        List<Category> list = entityManager.createNamedQuery("Category.findByName", Category.class).setParameter("name", value).getResultList();
        if (list.size() == 0) {
            return Response.status(404).build();
        }
        Category category = list.get(0);
        return Response.status(200).entity(category).build();
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
