class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.references :user, null: false
      t.string :title, limit: 80, null: false
      t.text :content, null: false, default: ""
      t.boolean :restricted, null: false, default: false

      t.timestamps
    end
  end
end
