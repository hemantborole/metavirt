class CreateManagers < Sequel::Migration
  
  def up
    create_table(:instances) do
      primary_key :id
      Integer :rank
      String :instance_id
      String :image_id
      String :status, :default=>'pending'
      String :public_ip
      String :internal_ip
      String :mac_address
      String :keypair
      String :authorized_keys
      String :remoter_base
      String :cloud
      String :pool
      Timestamp :updated_at
      Timestamp :created_at
      Text :ifconfig
    end
    
    create_table :machine_images do
      primary_key :id
      String :name
      String :remoter_base
    end
    create_table :clouds do
      primary_key :id
      String :name
      String :pool
      Text :content
      Text :json
    end
    create_table :pools do
      primary_key :id
      String :name
      Text :content
      String :filepath
    end
    create_table :remoter_bases do
      primary_key :id
      String :name
    end
    create_table :keypairs do
      primary_key :name
      String :private_key #optional
      String :public_key 
      String :source_path #optional, the path the key was added from, if known
      String :sourced_from_ip #the host that the key was added form
    end
  end
  
  def down() 
    drop_table :instances
    drop_table :machine_images
    drop_table :clouds
    drop_table :pools
    drop_table :remoter_bases
  end
  
end