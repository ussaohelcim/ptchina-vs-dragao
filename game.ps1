function PuxarJsonELimpar { param ($urljson)
	$ProgressPreference = 'SilentlyContinue'
	$sujo = Invoke-WebRequest -Uri $urljson  
	$limpo = $sujo.Content | ConvertFrom-Json -Depth 10
	return $limpo
}

function ResponderFio { param ([int]$numFio, $prancha, $msg)
	$linkPostar = "https://ptchan.org/forms/board/$prancha/post"
	$cabeca =  @{
		Referer = "https://ptchan.org/$prancha/thread/$numFio.html"
		#"x-using-xhr" = $true
		#"x-using-live" = $true
		origin = "https://ptchan.org"
		"content-type" =  "multipart/form-data; boundary=----WebKitFormBoundaryQkFZhvDYn94GQxeV"
	}
	$body = @{
		thread = $numFio # postId of the thread this post is replying to. If null, creates a new thread.
		name = "Dragão##teste"
		message = ""
		subject = ""
		email = "sage" #Email, or special values such as 'sage'.
		postpassword = "cubucetaxota" #Password required to delete the post later.
		#file = [System.IO.File]::ReadAllBytes(("Grof.jpg")) #("Grof.jpg") # One or more files, multipart form data.
		#file = [System.IO.FileStream]::new("Grof.jpg", [System.IO.FileMode]::Open) #("Grof.jpg") # One or more files, multipart form data.
		# spoiler = @("") #Array of sha256 hash of files to be spoilered.
		# spoiler_all = $false
		# strip_filename = @("") #Array of sha256 hash of files to have filenames stripped.. The sha256 hash will be used instead. Note: the server will still receive the original filenames before stripping.
		#customflag = "Índio" #string or null | Name of custom flag to be used. If null, will use no flag unless the board also has geoip flags enabled, then it will use the geo flag.
		customflag = "" #string or null | Name of custom flag to be used. If null, will use no flag unless the board also has geoip flags enabled, then it will use the geo flag.
		# captcha = "" #@(0) -or "" #Name of custom flag to be used. If null, will use no flag unless the board also has geoip flags enabled, then it will use the geo flag.
	}

	$body.message = $msg + "`n||spambypass:" + ((0..100)|Get-Random) +"||"
	#gambiarra para não cair como spam

	Invoke-WebRequest -Uri $linkPostar -Form $body -Method Post -Headers $cabeca
}

class Guerreiro {

	[void]LevarDano()
	{

	}
}
class Mago {
	[int]$vida
	[void]LevarDano()
	{
	
	}
}
class Jogador {
	$tripcode 
	$classe
	[int]$vida = 100
	[bool]$jaJogou
	#[int]$dano = 
	Jogador($tripcode)
	{
		$this.tripcode = $tripcode
		#$this.classe = $classe
	}
	[void]LevarDano([int]$dano)
	{
		$this.vida -= $dano
	}
}
class Dragao{
	$vida
	Dragao($vida)
	{
		$this.vida = $vida
	}
	LevarDano($dano)
	{
		$this.vida -= $dano
	}
}
function AtualizarLobby {
	
}

function AtacarDragão { param ($dano)
	
}

function TaNolobby {param ($tripcode)
	foreach($jogador in $lobby)
	{
		if($jogador.tripcode -ceq $tripcode)
		{
			return $true
		}
	}
	return $false
}

function GetJogadorFromTripcode {param ($tripcode)
	foreach($jogador in $lobby)
	{
		if($jogador.tripcode -ceq $tripcode)
		{
			return $jogador
		}
	}
}

function Get-Fio {
	return PuxarJsonELimpar -urljson $linkFio 
	#return (Get-Content -Path ".\fio.json") | ConvertFrom-Json -Depth 10
}

$linkFio = "https://ptchan.org/br/thread/69433.json"

[System.Collections.ArrayList]$lobby = @()

[Dragao]$dragao = [Dragao]::new(500)

$padraoDado = "##3d10="

$ultimo = 0

#[string]$s = ""
while($dragao.vida -gt 0)
{
	Start-Sleep -Seconds 60
	Clear-Host

	[string]$mensagemFinal = ""
	#mensagem que vai ser enviado para o fio
	$danoTotal = 0
	#dano total que os jogadores vão gerar 
	$danoDragao = ((20..30)|Get-Random)

	$fio = Get-Fio
	#dicionario do fio, convertido do json
	#$fio = (Get-Content -Path ".\fio.json") | ConvertFrom-Json -Depth 10

	foreach($reply in $fio.replies)
	{
		if($reply.nomarkup -eq "join" -and !(TaNolobby -tripcode $reply.tripcode)) #se a mensagem é join e não ta no lobby
		{
			$null = $lobby.Add([Jogador]::new($reply.tripcode))
			#adiciona jogador no lobby
		}
	}

	$numJogadoresVivos = 0

	if($lobby.Count -gt 0)
	{
		foreach($jogador in $lobby)
		{	#jogadores levar dano dragao
			if($jogador.vida -gt 0)
			{
				#Write-Host $jogador.tripcode "tinha" $jogador.vida "pontos de vida e levou" $danoDragao "pontos de dano"
				$mensagemFinal += $jogador.tripcode +" tinha "+ $jogador.vida +" pontos de vida e levou "+ $danoDragao +" pontos de dano`n"
				$jogador.LevarDano($danoDragao)
				if($jogador.vida -gt 0){$numJogadoresVivos++}
			}
			
		}
	}
	if($numJogadoresVivos -eq 0)
	{
		$mensagemFinal += "Não tem jogadores vivos no momento.`n"
		#Write-Host "Não tem jogadores vivos no momento."
	}
	
	foreach($reply in $fio.replies)
	{
		if(	$reply.postId -gt $ultimo -and 
			(TaNolobby -tripcode $reply.tripcode) -and 
			(GetJogadorFromTripcode -tripcode $reply.tripcode).vida -gt 0 
		)
		{
#-and !((GetJogadorFromTripcode -tripcode $reply.tripcode).jaJogou)
			if($reply.message.Contains('<span class="dice">') -and $reply.nomarkup.StartsWith($padraoDado))
			{
				$dano = [int]$reply.nomarkup.Replace($padraoDado,"")
				#remove os dados da mensagem

				$ultimo = $reply.postId
				#variavel para ajudar a ignorar mensagens que ja foram 'usadas'

				$dragao.LevarDano($dano)

				$danoTotal += $dano

				$mensagemFinal += $reply.tripcode + " deu " + $dano + " pontos de dano e tem "+ (GetJogadorFromTripcode -tripcode $reply.tripcode).vida +" pontos de vida`n"
				#(GetJogadorFromTripcode -tripcode $reply.tripcode).jaJogou = $true
				
			}

		}
	}

	$mensagemFinal += "Dano total no dragão: $danoTotal `n"
	$mensagemFinal += "Vida dragao: " + $dragao.vida
	Write-Host $mensagemFinal
	ResponderFio -numFio $fio.postId -prancha $fio.board -msg $mensagemFinal
}

ResponderFio -numFio $fio.postId -prancha $fio.board -msg "==O dragão foi derrotado!=="

Write-Host "O dragao foi derrotado"
