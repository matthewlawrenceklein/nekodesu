class DropWaniStudyMaterials < ActiveRecord::Migration[8.1]
  def up
    drop_table :wani_study_materials
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
