module PivotalStoryHelpers
  def generate_summary(length, with_special)
    result = ''
    chars = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten

    if with_special
      ["\t", "\n"].each { |char| chars << char }
      result += "\n \t"
    end

    result + (0...length).map { chars[rand(chars.length)] }.join
  end
end
