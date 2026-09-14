#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <math.h>

/* Shifts and rotates objects under the [NStationary] and [Buildings] headers of a  */
/* IL-2 mission file. The objects are placed around a point in the map whose        */
/* coordinates are given in the configuration file. The configuration file also     */
/* provides the rotation angle                                                      */
/* Use at your own risk!                                                            */
/* Created by Antonio M.                                                            */

int round(float x) 
{
	float temp = x;

	if ( ( x-floor( temp ) ) < 0.5) 
	{
		return(int)(floor(x));
	}
 	else 
	{
  		return(int)(ceil(x));
	}
}

int main( )
{
	FILE *InputFile, *OutputFile, *CfgFile;
	char InputString[201], ObjectId[30], ObjectName[100];
	int found, boh, first;
	float x, y, theta, x1, y1, theta1, alfadeg, alfa, pi, bohfloat, x_new, y_new,
              x_0, y_0;

	pi = acos(-1.);

	CfgFile = fopen("mission.cfg", "r");
	if (CfgFile == NULL ) 
	{
		printf("Error opening configuration file mission.cfg\n");
		exit(-1);
	}

	fscanf( CfgFile, "%f %f %f", &x_new, &y_new, &alfadeg );
	fclose (CfgFile);

	printf( "Input parameters: x_new = %.2f m, x_new = %.2f m, angle = %.2f deg\n", x_new, y_new, alfadeg ); 

	alfa = alfadeg*pi/180.0;

	InputFile = fopen("mission.mis", "r");
	if (InputFile == NULL ) 
	{
		printf("Error opening input file mission.mis\n");
		exit(-1);
	}


	OutputFile = fopen("mission1.mis", "w");
	if (OutputFile == NULL ) 
	{
		printf("Error opening Output file mission1.mis\n");
		exit(-1);
	}

	/* read and rewrite lines until arrive to "NStationary" */
	found = 0;
	while ( found == 0 )
	{
		fgets ( InputString, 200, InputFile );
		if( InputString == NULL )
		{
			printf ("Input file error!\n");
			exit(-1);
		}	
		if ( strstr ( InputString, "[NStationary]" ) == NULL )
		{
			fprintf( OutputFile, InputString, "%s\n" );
		
		}
		else
		{	
			found = 1;
			fprintf (OutputFile, "[NStationary]\n");
		}
	}
	
	/* process Stationary Objects */
	found = 0;
	first = 1;
	printf( "Processing stationary objects...\n" );
	while ( found == 0 )
	{
		fgets ( InputString, 200, InputFile );
		if( InputString == NULL )
		{
			printf ("Input file error!\n");
			exit(-1);
		}	

		if ( strstr ( InputString, "[Buildings]" ) == NULL )
		{

			sscanf( InputString, "%s %s %d %f %f %f %f ", ObjectId, ObjectName, &boh, &x, &y, &theta, &bohfloat );

			printf( "Processing %s ...\n", ObjectName );

			/* take the coordinates of the first point in the file as x_0, y_0 */
			if( first == 1 )
			{
				first = 0;
				x_0 = x;
				y_0 = y;
			}

			/* shift around point (0,0) */
			x -= x_0;
			y -= y_0;

			/* apply rotation */
			x1 = x * cos(alfa) + y * sin(alfa);
			y1 = -x * sin(alfa) + y * cos(alfa);
			theta1 = theta + alfadeg;

			/* shift to new coordinates */
			x1 += x_new;
			y1 += y_new;

			/* trick to avoid corruption of negative coordinates when */ 
                        /* saving the file with FMB (thanks to bird_brain)        */
			if ( x1 < 0 )
				x1 = round(x1);


			if ( y1 < 0 )
				y1 = round(y1);

fprintf( OutputFile, " s%s %s %d %.2f %.2f %.2f %5.2f \n ", ObjectId, ObjectName, boh, x1, y1, theta1, bohfloat );
			
		}
		else
		{	
			found = 1;
			fprintf (OutputFile, "[Buildings]\n" );
		}

	}
	/* process buildings */
	found = 0;
	printf( "Processing buildings...\n" );
	while ( found == 0 )
	{

		fgets ( InputString, 200, InputFile );
		if( InputString == NULL )
		{
			printf ("Input file error!\n");
			exit(-1);
		}	

		if (
			( strstr ( InputString, "[Target]" ) == NULL ) &&
			( strstr ( InputString, "[StaticCamera]" ) == NULL ) &&
			( strstr ( InputString, "[House]" ) == NULL ) &&
			( strstr ( InputString, "[Bridge]" ) == NULL ) 
		   )
		{

			sscanf( InputString, "%s %s %d %f %f %f", ObjectId, ObjectName, &boh, &x, &y, &theta );

			printf( "Processing %s ...\n", ObjectName );

			/* shift around point (0,0) */
			x -= x_0;
			y -= y_0;

			/* apply rotation */
			x1 = x * cos(alfa) + y * sin(alfa);
			y1 = -x * sin(alfa) + y * cos(alfa);
			theta1 = theta + alfadeg;

			/* shift to new coordinates */
			x1 += x_new;
			y1 += y_new;

			/* trick to avoid corruption of negative coordinates when */ 
                        /* saving the file with FMB (thanks to bird_brain)        */

			if ( x1 < 0 )
				x1 = round(x1);


			if ( y1 < 0 )
				y1 = round(y1);


			fprintf( OutputFile, " b%s %s %d %.2f %.2f %.2f \n ", 
					 ObjectId, ObjectName, boh, x1, y1, theta1 );
			
		}
		else
		{	
			found = 1;
			fprintf (OutputFile, "%s", InputString);
		}
	}

	
	/* copy rest of file */
	found = 0;
	while ( found == 0 )
	{
		if ( fgets ( InputString, 200, InputFile ) == NULL )
		{
			found = 1;
		}
		else
		{
			fprintf( OutputFile, "%s", InputString );
		}		
	}
	fclose (InputFile);
	fclose (OutputFile);
				
	exit(0);
}
