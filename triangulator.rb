require 'securerandom'

class Triangulator
  def initialize(num_participants, samples, seed)
    @num_participants = num_participants
    @samples = samples
    @seed = seed
  end

  def generate
    prng = Random.new(seed)
    1.upto(num_participants).map do
      choose(3, samples.dup, prng)
    end
  end

  private
  def choose(num, choices, prng)
    num.times.map do
      choices.delete_at(prng.rand(choices.length))
    end
  end

  attr_reader :num_participants, :samples, :seed
end

class DatasheetGenerator
  class Flight
    attr_reader :id, :samples
    def initialize(id, samples)
      @id = id
      @samples = samples
    end
  end

  def initialize(data)
    @data = enumerate_samples(data)
  end

  def generate
    datasheet = StringIO.new
    write_flights(datasheet)
    datasheet.puts "-"*80
    organize_samples(datasheet)
    datasheet.rewind
    return datasheet.read
  end

  private
  def write_flights(io)
    data.each do |flight|
      io.print "#{flight.id}.\t"
      flight.samples.each do |sample| 
        io.print("#{sample[:num]}:#{sample[:name]}\t")
      end
      io.print "\n"
    end
  end

  def organize_samples(io)
    sorted_samples = data.map(&:samples).flatten.group_by { |s| s[:name]}
    sorted_samples.keys.sort.each do |key|
      io.print("#{key}:\t")
      sorted_samples[key].each { |s| io.print("#{s[:num]} ")}
      io.print("\n")
    end
  end

  def enumerate_samples(data)
    [].tap do |results| 
      counter = 0
      data.reduce(1) do |id, row|
        samples = row.map { |sample_name| counter += 1; {num: counter, name: sample_name} }
        results << Flight.new(id, samples)
        id += 1
      end
    end
  end

  attr_reader :data
end

if __FILE__ == $0
  ONE_BILLION = 1_000_000_000

  require 'optparse'
  require 'ostruct'
  options = OpenStruct.new
  options.num_participants = 0
  options.samples = []
  options.seed = SecureRandom.random_number(ONE_BILLION)

  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    opts.on("--number PARTICIPANTS", Integer,
            "Number of PARTICIPANTS to generate data for") do |num_participants|
      options.num_participants = num_participants
    end

    opts.on("--samples x,y,z", Array, 'List of samples to use') do |samples|
      options.samples = samples
    end

    opts.on("--seed SEED", Integer, 'Use a predetermined seed') do |seed|
      options.seed = seed
    end
  end.parse!

  if options.num_participants <= 0 || options.samples.length <= 3
    puts "Invalid information was provided. You must have at least 1 participant and 4 samples to choose from"
    exit(1)
  end

  triang = Triangulator.new(options.num_participants, options.samples, options.seed)
  datasheet = DatasheetGenerator.new(triang.generate)
  puts "Seed: #{options.seed}"
  puts "Generated On: #{Time.now}"
  puts ""
  puts "#{datasheet.generate}"
end
