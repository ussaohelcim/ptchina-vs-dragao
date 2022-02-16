$ProgressPreference = 'SilentlyContinue'
#isso serve para não mostrar barras de progresso no powershell quando fazer requisições web
function PuxarJsonELimpar { param ($urljson)
	$sujo = Invoke-WebRequest -Uri $urljson  
	$limpo = $sujo.Content | ConvertFrom-Json -Depth 10
	return $limpo
}

function ResponderFio { param ([int]$numFio, $prancha, $msg)
	$linkPostar = "https://ptchan.org/forms/board/$prancha/post"
	$cabeca =  @{
		Referer = "https://ptchan.org/$prancha/thread/$numFio.html"
		origin = "https://ptchan.org"
	}
	$body = @{
		thread = $numFio 
		name = "Dragão##teste"
		message = ""
		email = "sage" 
		postpassword = [string]((0..789456)|Get-Random) 
	}

	$body.message = $msg + "`n||spambypass:" + ((0..100)|Get-Random) +"||"
	#gambiarra para não cair como spam

	Invoke-WebRequest -Uri $linkPostar -Form $body -Method Post -Headers $cabeca
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

function TaMorto { param ($tripcode)
	$cemiterio = Get-Content -Path ".\cemiterio.json" | ConvertFrom-Json -Depth 10
	foreach($morto in $cemiterio.mortos)
	{
		if($morto.tripcode -ceq $tripcode)
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
	return $null
}

function Get-Fio {
	return PuxarJsonELimpar -urljson $linkFio 
	#return (Get-Content -Path ".\fio.json") | ConvertFrom-Json -Depth 10
}
#region Classes
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
#endregion

$conf = Get-Content -Path ".\conf.json" | ConvertFrom-Json -Depth 10

$linkFio = $conf.linkFio #"https://ptchan.org/br/thread/69433.json"
$padraoDado = $conf.padraoDado #"##3d10="

#[Dragao]$dragao = [Dragao]::new(500)
[Dragao]$dragao = [Dragao]::new($conf.vidaDragao)

[System.Collections.ArrayList]$lobby = @()
$ultimo = $conf.ultimoId #0

$fio = Get-Fio

ResponderFio -numFio $fio.postId -prancha $fio.board -msg "rwaaa. Nova partida começando."

while($dragao.vida -gt 0)#game loop
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
		if(	$reply.nomarkup -eq "join" -and 
			!(TaNolobby -tripcode $reply.tripcode) -and
			!(TaMorto -tripcode $reply.tripcode) -and
			$reply.postId -gt $ultimo -and
			$reply.tripcode -ne ""
		) #se a mensagem é join, tripcode não ta no lobby, não ta no cemiterio
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
				$mensagemFinal += $jogador.tripcode +" tinha "+ $jogador.vida +" pontos de vida e levou "+ $danoDragao +" pontos de dano`n"
				$jogador.LevarDano($danoDragao)
				if($jogador.vida -gt 0){$numJogadoresVivos++}
			}
		}
	}

	if($numJogadoresVivos -eq 0)
	{
		$mensagemFinal += "Não tem jogadores vivos no momento.`n"
	}
	
	foreach($reply in $fio.replies)
	{
		if(	$reply.postId -gt $ultimo -and 
			(TaNolobby -tripcode $reply.tripcode) -and 
			(GetJogadorFromTripcode -tripcode $reply.tripcode).vida -gt 0 
		)
		{
			if($reply.message.Contains('<span class="dice">') -and $reply.nomarkup.StartsWith($padraoDado))
			{
				$dano = [int]$reply.nomarkup.Replace($padraoDado,"")
				#remove os dados da mensagem

				$ultimo = $reply.postId
				#variavel para ajudar a ignorar mensagens que ja foram 'usadas'

				$dragao.LevarDano($dano)

				$danoTotal += $dano

				$mensagemFinal += $reply.tripcode + " deu " + $dano + " pontos de dano e tem "+ (GetJogadorFromTripcode -tripcode $reply.tripcode).vida +" pontos de vida`n"
			}
		}
	}

	$mensagemFinal += "Dano total no dragão: $danoTotal `n"
	$mensagemFinal += "Vida dragao: " + $dragao.vida
	Write-Host $mensagemFinal
	ResponderFio -numFio $fio.postId -prancha $fio.board -msg $mensagemFinal
}

Start-Sleep -Seconds 60

ResponderFio -numFio $fio.postId -prancha $fio.board -msg "==O dragão foi derrotado!=="

Write-Host "O dragao foi derrotado"

#region Pós jogo

[System.Collections.ArrayList]$caixoes = @()

[System.Collections.ArrayList]$mortos = @()
[System.Collections.ArrayList]$vivos = @()

$muralDeHonra = Get-Content -Path ".\mural de honra.json" | ConvertFrom-Json -Depth 10

$cemiterio = Get-Content -Path ".\cemiterio.json" | ConvertFrom-Json -Depth 10

foreach($jogador in $lobby)
{
	if($jogador.vida -le 0)
	{
		$null = $caixoes.Add(
			@{
				tripcode = $jogador.tripcode
				dataMorte = (Get-Date -UFormat "%T %d de %B de %Y.").ToString()
				classe = "danone"
				origem = "Sei la."
				motivo = "Virou cinzas depois de um bafo do dragão"
			}
		)
		$null = $mortos.Add( $jogador.tripcode )
	}
	else {
		$null = $vivos.Add( $jogador.tripcode )
	}
}
$muralDeHonra.batalhas += @{
	dataBatalha = (Get-Date -UFormat "%T %d de %B de %Y.").ToString()
	jogadoresMortos = $mortos
	jogadoresSobreviventes = $vivos
}

Set-Content -Path ".\mural de honra.json" -Value ($muralDeHonra | ConvertTo-Json -Depth 10)

if($caixoes.Count -gt 0)
{
	Set-Content -Path ".\cemiterio.json" -Value ($cemiterio | ConvertTo-Json -Depth 10)
}
#endregion 