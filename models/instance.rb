module MetaVirt
  class Instance < Sequel::Model
    
    def self.safe_create(params)
      cols = [:authorized_keys, :keypair, :image_id]
      safe_params = cols.inject({}) {|hsh, k| hsh[k]=params[k]; hsh}
      safe_params[:authorized_keys] ||= params[:public_key]
      inst = self.create(safe_params.merge(:created_at=>Time.now))
      inst.update(:instance_id=>inst.id)  #give this temporarily until real instance_id is returned from remoter_base
      inst
    end

    def to_json
      values.to_json
    end
    
    def self.to_json(filters=nil)
      if filters
        rows = dataset.filter(filters)
      else
        rows = dataset.all
      end
      rows.collect{|row| row.values}.to_json
    end
  end
end