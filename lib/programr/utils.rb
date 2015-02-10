module ProgramR
  module Cache
    def self.dumping(aFilename,theGraphMaster)
      File.open(aFilename,'w') do |file|
        file.write(Marshal.dump(theGraphMaster,-1))
      end
    end

    def self.loading(aFilename)
      File.open(aFilename,'r') do |file|
        return Marshal.load(file.read)
      end rescue nil
    end
  end # module Cache
end #module ProgramR
