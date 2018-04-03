module Cucumber
    module Tasks
        class Settle < Roby::Task
            # You usually want this
            terminates
        
            poll do
                should_wait = plan.tasks.any? do |t|
                    if t.each_event.any?(&:pending?)
                        true
                    elsif t.running? && t.has_event?('ready') && t.each_executed_task.find { true }
                        t.ready_event.emitted?
                    end
                end
                if !should_wait
                    success_event.emit
                end
            end
        end
    end
end
