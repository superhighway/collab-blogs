# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

admin = User.create!(admin: true, email: "admin@localhost.net",
  password: "Loader578", password_confirmation: "Loader578")
writer = User.create!(email: "writer@localhost.net",
  password: "Plumber364", password_confirmation: "Plumber364")
junior = User.create!(email: "junior@localhost.net",
  password: "Plumber364", password_confirmation: "Plumber364")

Post.create!(user: admin, title: "Cool Day",
  content: "It has been raining since ages. I really love it because recently it has been really hot outside, like 40 degrees Celcius.")
Post.create!(user: writer, title: "Hot Day",
  content: "The sun seems to like me very much these days. I don't really mind, but I really wish it could love someone else too.")
Post.create!(user: writer, title: "Lorem Ipsum in Another Language",
  content: "What do you guys think of yet another kind of Lorem Ipsum? Perhaps it could be translated literally to another language.")
Post.create!(user: junior, title: "Hello!",
  content: "Hey! I'm pretty new here! Glad to be here! This is my first time here, so please be nice to me (and each other).")
