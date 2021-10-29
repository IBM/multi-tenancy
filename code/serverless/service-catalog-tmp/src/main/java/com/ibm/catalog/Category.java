package com.ibm.catalog;

import javax.persistence.*;

@Entity
@Table(name = "category")
@NamedQuery(name = "Category.findAll", query = "SELECT f FROM Category f ORDER BY f.name")
@NamedQuery(name = "Category.findByName", query = "SELECT f FROM Category f WHERE f.name=:name")
public class Category {

    @Id
    @SequenceGenerator(name = "categorySequence", sequenceName = "category_id_seq", allocationSize = 1, initialValue = 10)
    @GeneratedValue(generator = "categorySequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    @Column
    private Integer parent;

    public Category() {
    }

    public Category(String name) {
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

    public Integer getParent() {
        return parent;
    }

    public void setParent(Integer parent) {
        this.parent = parent;
    }

}
