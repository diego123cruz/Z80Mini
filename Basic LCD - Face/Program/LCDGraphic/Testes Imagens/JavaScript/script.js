
var imageFile = "";
var zoom = false;

var text_color_index = 0x0;
    var background_color_index = 0x0a;
    /* 0 - Black, 1 - dark blue, 2 - dark green, 3 - dark cyan,
     * 4 - dark red, 5 - dark purple, 6 - brown, 7 - light grey,
     * 8 - dark grey, 9 - blue, 10 - green, 11 - cyan,
     * 12 - red, 13 - purple, 14 - yellow, 15 - white */
     const palette16 = [ "#000000", "#0000aa", "#00aa00", "#00aaaa",
                        "#aa0000", "#aa00aa", "#aa5500", "#aaaaaa",
                        "#555555", "#5555ff", "#55ff55", "#55ffff",
                        "#ff5555", "#ff55ff", "#ffff55", "#ffffff" ];


    function drawCharacter(ctx, image) {
        console.clear();
        const bitmaps = image;
        var index = 0;
        var xx = 0;
        for(var y=0; y<64; y++) {
            for(var x=0; x<16; x++) {
                const line = bitmaps[index];
                for (var bits = 0; bits < 8; bits++) {
                    const bit = (line >> (7 - bits)) & 1;
                    ctx.fillStyle = (bit == 1) ? palette16[text_color_index] :
                                                palette16[background_color_index];
                    ctx.fillRect(xx, y, 1, 1);
                    xx++;
                }
                index++;
            }
            xx=0;
        }
    }


    function renderImage() {
      var imageDataString = "";
      navigator.clipboard.readText().then((clipboardText) => {
        imageDataString = clipboardText;
        imageFile = clipboardText;

        const imageDataArray = imageDataString.trim().split(",");
        const imageData = imageDataArray.map(hex => parseInt(hex, 16));

        const canvas = document.getElementById("canvas");
        const context = canvas.getContext("2d");
        if (zoom == false) {
          context.scale(2,2);
          zoom = true;
        }
        
        context.clearRect(0, 0, canvas.width, canvas.height);
        drawCharacter(context, imageData);

      })

    }










    function decimalToHexadecimal(decimalNumber) {
      if (isNaN(decimalNumber) || decimalNumber < 0 || decimalNumber > 65535) {
        return "O número deve estar entre 0 e 65535.";
      }
    
      const hexadecimal = decimalNumber.toString(16).toUpperCase();
      const paddedHexadecimal = ("0000" + hexadecimal).slice(-4);
    
      return "0x" + paddedHexadecimal.substr(0, 2) + ", 0x" + paddedHexadecimal.substr(2, 2);
    }


// Função para converter um byte em formato hexadecimal com '0x' no início
function byteToHex(byte) {
  return '0x' + ('00' + byte.toString(16)).slice(-2);
}

// Função para ler o arquivo selecionado pelo usuário
function handleFile(file) {
  const reader = new FileReader();

  reader.onload = function (event) {

    document.getElementById("inputHex").value = event.target.result;
  };

  reader.readAsText(file);
}

function textToHexadecimal(text) {
  if (typeof text !== "string" || text.length > 16) {
    return "O texto deve ser uma string com no máximo 16 letras.";
  }

  let hexString = "";
  for (let i = 0; i < text.length; i++) {
    const charCode = text.charCodeAt(i).toString(16).toUpperCase();
    const paddedCharCode = ("00" + charCode).slice(-2);
    hexString += "0x" + paddedCharCode + ", ";
  }

  // Preenche com "0x00" caso o texto tenha menos de 16 letras
  while (hexString.length < 16 * 6 - 2) {
    hexString += "0x00, ";
  }

  return hexString.substr(0, 16 * 6 - 2);
}

var saidaCodHex = "";
var saidaCodSize = "";
var saidaCodName = "";

function convertTextToHex(append) {
  const inputText = document.getElementById("inputText").value;
  const hexadecimalResult = textToHexadecimal(inputText);
  saidaCodName = hexadecimalResult;











  const content = document.getElementById("inputHex").value;
  const lines = content.split('\n');
  const hexOutput = [];

  lines.forEach(line => {
    if (line.startsWith(':')) {
      const data = line.slice(1); // Remover o caractere ':' do início da linha
      const byteCount = parseInt(data.slice(0, 2), 16);
      const address = parseInt(data.slice(2, 6), 16);
      const recordType = parseInt(data.slice(6, 8), 16);
      
      if (recordType === 0) { // Verificar se é um registro de dados
        for (let i = 0; i < byteCount; i++) {
          const byte = parseInt(data.slice(8 + i * 2, 10 + i * 2), 16);
          hexOutput.push(byteToHex(byte));

        }
      }
    }
  });

  console.log(hexOutput.join(', '));
  saidaCodHex = hexOutput;

  const buffer = hexOutput.slice(",");
  const byteCount = buffer.length;
  const counthex = decimalToHexadecimal(byteCount);
  
  console.log(" size:", counthex);
  saidaCodSize = counthex;
  var typeFile = document.getElementById('selectType').value;

  if (typeFile == "0x01") {
    saidaCodSize = "0x04,0x00";
    saidaCodHex = imageFile;
  }




  if (append) {
    document.getElementById("outputHex").value += ",0x44,"+saidaCodName+","+typeFile+","+saidaCodSize+","+saidaCodHex+",0x4F";
  } else {
    document.getElementById("outputHex").value = "0x44,"+saidaCodName+","+typeFile+","+saidaCodSize+","+saidaCodHex+",0x4F";
  }
  
}



const inputFile = document.getElementById('fileInput');
 inputFile.addEventListener('change', function (event) {
   const file = event.target.files[0];
   handleFile(file);
 });

 function clean_hex(input, remove_0x) {
  input = input.toUpperCase();
  
  if (remove_0x) {
    input = input.replace(/0x/gi, "");        
  }
  
  var orig_input = input;
  input = input.replace(/[^A-Fa-f0-9]/g, "");
  if (orig_input != input)
      //alert ("Warning! Non-hex characters (including newlines) in input string ignored.");
  return input;    
} 

function ConvertToHex() {
  const numDec = document.getElementById("decNum").value;
  const hexNum = decimalToHexadecimal(parseInt(numDec));
  document.getElementById("outHexConv").value = hexNum;
}

function Convert() {
var cleaned_hex = clean_hex(document.frmConvert.hex.value, true);
var filename = document.frmConvert.filename.value;	  
//document.frmConvert.cleaned_hex.value = cleaned_hex;
if (cleaned_hex.length % 2) {
  alert ("Error: cleaned hex string length is odd.");     
  return;
}

var binary = new Array();
for (var i=0; i<cleaned_hex.length/2; i++) {
  var h = cleaned_hex.substr(i*2, 2);
  binary[i] = parseInt(h,16);        
}

// Download .txt
const text = document.getElementById("outputHex").value;
const blob = new Blob([text], { type: "text/plain" });

const aTxt = document.createElement("a");
aTxt.href = URL.createObjectURL(blob);
aTxt.download = filename+".txt";

// Append anchor to body.
document.body.appendChild(aTxt)
aTxt.click();

// Remove anchor from body
document.body.removeChild(aTxt)     




// Download .bin
var byteArray = new Uint8Array(binary);
var a = window.document.createElement('a');

a.href = window.URL.createObjectURL(new Blob([byteArray], { type: 'application/octet-stream' }));
a.download = filename;

// Append anchor to body.
document.body.appendChild(a)
a.click();

// Remove anchor from body
document.body.removeChild(a)        
} 


function onClangeSelect() {
  var typeFile = document.getElementById('selectType').value;
  document.getElementById("divCode").style.display = "block";
  document.getElementById("divImage").style.display = "block";

  if (typeFile == "0x00") {
    document.getElementById("divImage").style.display = "none";
  }

  if (typeFile == "0x01") {
    document.getElementById("divCode").style.display = "none";
  }
}