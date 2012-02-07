#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'rubygems'
require 'xml/libxml'
require 'progressbar'
require 'date'
require 'csv'

Net::HTTP.version_1_1

HOST = "localhost"
PORT = "8000"
USER = "ormaster"
PASSWD = "ormaster123"

CONTENT_TYPE = "application/xml"
$body = ""
$date = ""
$csvName = "./examList"
$apires = ""

def setBody(id, dt, sq, insNum)
    $body = <<-EOS
      <data>
	<record>
	  <record name="medicalgetreq">
	    <string name="Patient_ID">#{id}</string>
	    <string name="Perform_Date">#{dt}</string>
	    <record name="Medical_Information">
	      <string name="Department_Code">#{$dipCode}</string>
	      <string name="Sequential_Number">#{sq}</string>
	      <string name="Insurance_Combination_Number">#{insNum}</string>
	      <record name="HealthInsurance_Information">
		<string name="InsuranceProvider_Class"></string>
		<string name="InsuranceProvider_WholeName"></string>
		<string name="InsuranceProvider_Number"></string>
		<string name="HealthInsuredPerson_Symbol"></string>
		<string name="HealthInsuredPerson_Number"></string>
		<array name="PublicInsurance_Information">
		  <record>
		    <string name="PublicInsurance_Class"></string>
		    <string name="PublicInsurance_Name"></string>
		    <string name="PublicInsurer_Number"></string>
		    <string name="PublicInsuredPerson_Number"></string>
		  </record>
		</array>
	      </record>
	    </record>
	  </record>
	</record>
      </data>
    EOS
end

def requestApi(classNo, reqxml)
    req = Net::HTTP::Post.new("/api01r/medicalget?class=0" + classNo)
    req.content_length = reqxml.size
    req.content_type = CONTENT_TYPE
    req.body = reqxml
    req.basic_auth(USER, PASSWD)

    Net::HTTP.start(HOST, PORT) {|http|
      res = http.request(req)

      $apires = res.body
      $xml = LibXML::XML::Document.string($apires)
    }

=begin
    @filename = './res/' + classNo + "_" + $date +  '.xml'
    File.open(@filename, 'w') {|f|
      f.write res.body
    }
    @uri = open(@filename) do |f|
      f.read
    end
    }
    $xml = LibXML::XML::Document.string(@uri)
    $xml.save(@filename, :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
=end

end

def makeExamCsv()
    i = 0
    j = 0
    csv = ""
    listH = [""]
    listF = [""]

    csv.concat("{" + $ptId + "," + $insNum + "," + $seq + "," + $date + "}" + "\r\n")

    $xml.root.find( '/data/record/record/array/record/array/record' ).each do |elem|
      
      elem.find('string').each do |node|
	if (node.content != "") then
	  listH[i] = node.content
	  i = i + 1
	end
      end 
      if (listH.size == 6)
	listH[5].concat("\r\n")
	csv.concat(listH.join(','))
      end
      listH.clear
      i = 0

      elem.find('array').each do |node|
	node.find('record').each do |node2|
	  node2.find('string').each do |node3|
	    if (node3.content != "")
	      listF[j] = node3.content
	    else
	      break
	    end
	    j = j + 1
	  end

	  if (listF.size == 3)
	    listF[2].concat("\r\n")
	    csv.concat(listF.join(','))
	  end

	  listF.clear
	  j = 0
	end
      end
    end

    #File.open($csvName + "_" + $ptIdd + ".csv", 'a') {|f|
    File.open($csvName + ".csv", 'a') {|f|
      f.write csv
    }
end

# class :01 受信履歴取得
#       :02 日別診療情報取得
#       :03 月別診療情報取得
#
#1.患者番号       Patient_ID            (REQUIRED)
#2.診療年月(日)   Perform_Date          (IMPLIED)
#3.診療科コード   Department_Code       (REQUIRED)
#4.連番           Sequential_Number     (IMPLIED)
#
#  REQUIRED : 必須   IMPLIED : 任意

system("date")

#puts "診療科コードを入力してください(例:01)"
#$dipCode = gets.chomp
$dipCode = "01"
#puts "患者番号の桁数を入力して下さい"
#$idLen = gets.chomp
#puts "10"
$idLen = "5"

if File.exist?($csvName)
  File.delete($csvName)
end


$idx = 0
$rowcount = 0
CSV.open("test.csv", "r") do |row|
  $rowcount = $rowcount + 1
end

$ptime = $rowcount * 3.5 / 60
$inc = 1
$pbar = ProgressBar.new("now getting.", $rowcount.to_i)

now = DateTime.now
str = now.strftime("開始時刻:%Y年 %m月 %d日 %H時 %M分")
puts str
endtime = now + Rational($ptime.to_i, 24*60)
str = endtime.strftime("終了時刻:%Y年 %m月 %d日 %H時 %M分 (予定)")
puts str

CSV.open("test.csv", "r") do |row|
  $idx = $idx + 1
  #p $idx
  $ptId = row[0]
  $date = row[1].to_s
  $date = $date[0..3] + "/" + $date[4..5] + "/" + $date[6..7]
  $insNum = row[2]
  $seq = row[3]
  setBody($ptId, $date, $seq, $insNum)
  requestApi("2", $body)
  makeExamCsv()
  $apires = ""
  $ptbf = $ptId
  $pbar.inc($inc)
  system("rm /tmp/blob/*")
end
$pbar.finish

=begin
  p $ptId
  p $date
  p $insNum
  p $seq
=end

system("date")
puts "finish"


