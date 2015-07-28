module Bpl

  module AST
    class Identifier < Expression
      def ident; self end
    end
    class MapSelect < Expression
      def ident; @map.ident end
    end
  end

  module Analysis
    class ModifiesCorrection < Bpl::Pass
      def self.description
        "Correct procedure modifies annotations."
      end

      def run! program
        work_list = []
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          work_list << proc
          proc.specifications.dup.each do |sp|
            sp.remove if sp.is_a?(ModifiesClause) || sp.is_a?(AccessesClause)
          end if proc.body
          mods = Set.new
          accs = Set.new
          proc.each do |elem|
            case elem
            when StorageIdentifier
              accs << elem.name if elem.is_global?
            when HavocStatement
              mods += elem.identifiers.select(&:is_global?).map(&:name)
            when AssignStatement
              mods += elem.lhs.map(&:ident).select(&:is_global?).map(&:name)
            when CallStatement
              mods += elem.assignments.map(&:ident).select(&:is_global?).map(&:name)
            end
          end
          proc.append_children(:specifications,
            ModifiesClause.new(identifiers: mods.map{|id| bpl(id)})) \
            unless mods.empty?
          proc.append_children(:specifications,
            AccessesClause.new(identifiers: accs.map{|id| bpl(id)})) \
            unless accs.empty?
        end

        until work_list.empty?
          proc = work_list.shift
          targets = proc.callers
          targets << proc.declaration if proc.respond_to?(:declaration) && proc.declaration
          targets.each do |caller|
            mods = proc.modifies.map(&:name) - caller.modifies.map(&:name)
            accs = proc.accesses.map(&:name) - caller.accesses.map(&:name)
            caller.append_children(:specifications,
              ModifiesClause.new(identifiers: mods.map{|id| bpl(id)})) \
              unless mods.empty?
            caller.append_children(:specifications,
              AccessesClause.new(identifiers: accs.map{|id| bpl(id)})) \
              unless accs.empty?
            work_list |= [caller] unless mods.empty? && accs.empty?
          end
        end
      end
    end
  end

  # module AST
  #   class ProcedureDeclaration
  #     def add_modifies!(mods)
  #       work_list = [self]
  #       until work_list.empty?
  #         proc = work_list.shift
  #         new_mods = mods - proc.modifies
  #         unless new_mods.empty?
  #           proc.specifications << bpl("modifies #{new_mods.to_a * ", "};")
  #           work_list += proc.callers.to_a - work_list
  #         end
  #       end
  #     end
  #   end
  # end

end
