//
//  MiEjemploPushAppDelegate.m
//  MiEjemploPush
//
//  Created by Alberto Moraga on 13/05/10.
//  Copyright GotFeeling 2010. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "MiEjemploPushAppDelegate.h"
#import "MiEjemploPushViewController.h"

@implementation MiEjemploPushAppDelegate

@synthesize window;
@synthesize viewController;


//No hay que olvidarse de elegir el "Code Signing Identity" correcto en el proyecto y de cambiar el "Bundle identifier"
//en el info.plist (en este caso es com.gotfeeling.foobar).

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	//Aquí habría que hacer una comprobación sobre el iconBadgeNumber, si es distinto de 0, habría que pedirle al servidor que nos mandara
	//los cambios. En este caso simplemente lo ponemos a 0 para que el icono de la aplicación no tenga ningún globo de notificación.
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	
	
	//Registramos las notificaciones que queremos que la aplicación reciba.
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	return YES;
}

//Este método simplemente envía al servidor el token, en este caso lo enviamos en JSON.
- (void)sendToken:(NSString *)tokenString {
	NSString *requestString = [NSString stringWithFormat:@"{\"device\":{\"token\":\"%@\"}}",tokenString];
	NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
	
	NSMutableURLRequest *post = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://dev.gotfeeling.com/devices"]];
	[post addValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[post addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[post setHTTPMethod:@"POST"];
	[post setHTTPBody:requestData];
	
	NSURLResponse *response = nil;
	NSData *returnData = [NSURLConnection sendSynchronousRequest:post returningResponse:&response error:nil];
	NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
	NSLog(@"%@",returnString);
}

//Métodos delegados
//Este método recibe el token que apple nos manda. Le damos formato y llamamos al método de envío.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	
	//Hay que tener en cuenta que el usuario puede cambiar las notificaciones que quiere recibir para cualquier aplicación
	//que tenga instalada. Es tarea nuestra controlar las notificaciones que recibe cuando está corriendo la aplicación.
	
	//Comprobamos los tipos de notificaciones que el usuario tiene activas para nuestra aplicación.
	NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
	
	//Activamos las que sean necesarias.
	pushBadge = @"disabled";
	pushAlert = @"disabled";
	pushSound = @"disabled";
	
	if(rntypes == UIRemoteNotificationTypeBadge){
		pushBadge = @"enabled";
	}
	else if(rntypes == UIRemoteNotificationTypeAlert){
		pushAlert = @"enabled";
	}
	else if(rntypes == UIRemoteNotificationTypeSound){
		pushSound = @"enabled";
	}
	else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)){
		pushBadge = @"enabled";
		pushAlert = @"enabled";
	}
	else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)){
		pushBadge = @"enabled";
		pushSound = @"enabled";
	}
	else if(rntypes == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
		pushAlert = @"enabled";
		pushSound = @"enabled";
	}
	else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
		pushBadge = @"enabled";
		pushAlert = @"enabled";
		pushSound = @"enabled";
	}

	
	
	NSString *tokenString = [deviceToken description];
	tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
	tokenString = [tokenString stringByReplacingOccurrencesOfString:@"<" withString:@""];
	tokenString = [tokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
	
	[self sendToken:tokenString];

}


//Si ha habido un error al registrar las notificaciones y no hemos recibido el token correctamente, este método recibe el 
//error.
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Registration error: %@", error);
}


//Este método delegado es llamado cuando, estando dentro de la aplicación, recibimos una notificación push. 
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
	
	//Ya sabemos que puede ser de tres tipos, sonido, alerta, globo informativo en el icono de la aplicación.
	
	//Gestionamos cada una de las tres.
	
	NSString *sound = (NSString *)[apsInfo objectForKey:@"sound"];
	NSLog(@"Received Push Sound: %@", sound);
	//Si recibe una notificación sonora y el usuario no las ha desactivado, reproducimos el sonido.
	if (sound != nil && [pushSound compare:@"enabled"] == NSOrderedSame) {
		//El servidor no nos manda el archivo de sonido, nos manda el nombre completo (en este caso test.wav) del archivo
		//que la aplicación debe reproducir. Este archivo debe estar en la raiz del proyecto, sin estar localizado (nada de tener 
		//un archivo por idioma).
		NSString *soundPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],sound];	
		SystemSoundID soundID;
		AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
		AudioServicesPlaySystemSound (soundID);	
	}

	//Si recibe una notificación de alerta y el usuario no las ha desactivado, mostramos un cuadro de alerta, en este caso 
	//con un solo botón de OK.
	NSString *alert = [apsInfo objectForKey:@"alert"];
	NSLog(@"Received Push Alert: %@", alert);
	if (alert != nil && [pushAlert compare:@"enabled"] == NSOrderedSame) {
		UIAlertView *alertEvent = [[UIAlertView alloc] initWithTitle:@"Meetapp demo" message:[NSString stringWithFormat:@"%@",alert]
															delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];	
		[alertEvent show];
		[alertEvent release];		
	}
	
	//Si recibe una notificación de globo informativo, en este caso simplemente ponemos el iconBadgeNumber a 0, pues se supone que
	//ya le hemos mostrado al usuario las nuevas notificaciones.
	NSString *badge = [apsInfo objectForKey:@"badge"];
	NSLog(@"Received Push Badge: %@", badge);
	if ([pushBadge compare:@"enabled"] == NSOrderedSame) {
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];		
	}
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
