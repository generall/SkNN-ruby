require 'pry'

def foo(&block)
	x = 7
	yield x,8
end

class Dist
	def set_param(p)
		@z = p
	end

	def metric_foo
		Proc.new do |x,y| 
			p "proc #{@z}: #{x},#{y}" 
		end
	end
end

m = Dist.new
m.set_param(88)

foo(&m.metric_foo)

m.set_param(77)
foo(&m.metric_foo)
