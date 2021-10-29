package com.ibm.catalog;

import javax.persistence.*;

@Entity
@Table(name = "product")
@NamedQuery(name = "Product.findAll", query = "SELECT f FROM Product f ORDER BY f.name")
@NamedQuery(name = "Product.findByName", query = "SELECT f FROM Product f WHERE f.name=:name")
@NamedQuery(name = "Product.findById", query = "SELECT f FROM Product f WHERE f.id=:id")
public class Product {

    @Id
    @SequenceGenerator(name = "productSequence", sequenceName = "product_id_seq", allocationSize = 1, initialValue = 10)
    @GeneratedValue(generator = "productSequence")
    private Integer id;

    @Column
    private Double price;

    @Column(length = 100 , unique = true)
    private String name;

    @Column(length = 200)
    private String description;

    @Column(length = 100)
    private String image;


    public Product() {
    }

    public Product(String name) {
        this.name = name;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }


    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }
}
