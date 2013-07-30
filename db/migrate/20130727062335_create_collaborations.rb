class CreateCollaborations < ActiveRecord::Migration
  def change
    create_table :collaborations do |t|
      t.references :user, null: false
      t.references :post, null: false
    end
  end
end
