module Content::EntryImporter::CFR
  extend Content::EntryImporter::Utils
  provides :cfr_title, :cfr_part
  
  def cfr_node
    @cfr_node ||= mods_node.xpath('./xmlns:extension/xmlns:cfr').first if mods_node
  end
  
  def cfr_title
    cfr_node['title'] if cfr_node
  end
  
  def part_node
    @part_node ||= cfr_node.xpath('./xmlns:part').first if cfr_node
  end
  
  def cfr_part
    part_node['number'] if part_node
  end
  
end