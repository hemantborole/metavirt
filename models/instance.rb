class Instance < Sequel::Model
  DB.create_table(:instances) do
    primary_key :launch_id
    String :id
    String :status
    String :image_id
    String :public_ip
    String :internal_ip
    String :keypair_name
    String :public_key, :default=>default_key
  end unless DB.table_exists?(:instances)
end